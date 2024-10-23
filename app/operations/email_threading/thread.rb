# frozen_string_literal: true

# Based on the algorithm described at https://www.jwz.org/doc/threading.html.
class EmailThreading::Thread < ApplicationOperation
  class Container
    attr_accessor :message, :parent, :children

    def initialize(message:, parent: nil, children: [])
      @message = message
      @parent = parent
      @children = children
    end

    def self_or_descendant?(target)
      return true if self == target

      children.each do |child|
        return true if child.self_or_descendant?(target)
      end

      false
    end

    def dummy?
      message.nil?
    end

    def root?
      parent.nil?
    end

    def add_child(child)
      child.parent.remove_child(child) if child.parent.present?

      @children.push(child)
      child.parent = self
    end

    def remove_child(child)
      if @children.delete(child).nil?
        raise ArgumentError,
              "Removing non-existent child of #{message.inspect}"
      end

      child.parent = nil
    end

    def flatten
      result = []
      result.push(self)
      children.each do |child|
        result.push(*child.flatten)
      end

      result
    end
  end

  class Message
    attr_reader :db_id, :sort_field, :message_id, :references, :message_id_hash, :reference_hashes

    def initialize(
      message_id:,
      in_reply_to:,
      references:,
      sort_field:,
      db_id:
    )
      @sort_field = sort_field
      @db_id = db_id

      @message_id = message_id
      @references = references
      references.push(in_reply_to)
      references.compact_blank!
      references.uniq!

      @message_id_hash = message_id.hash
      @reference_hashes = references.map(&:hash)
    end
  end

  param :messages, [Types::Instance(Message)]

  # rubocop:disable Layout/EmptyLinesAroundBlockBody, Style/Next
  def call
    # In a rare cases the message we want to find a thread for can have a `duplicate` in our DB.
    # To amend removing it with `uniq!` let's insert it back replacing its duplicate.
    message_to_thread = messages.find { _1.db_id == -1 }
    messages.uniq!(&:message_id)
    if messages.none? { _1.db_id == -1 } && message_to_thread.present?
      messages[
        messages.index { _1.message_id == message_to_thread.message_id }
      ] = message_to_thread
    end

    id_table = {}

    # 1. For each message:
    messages.each do |message|

      # A. If id_table contains an empty Container for this ID:
      # - Store this message in the Container's message slot.
      current_container =
        if id_table.key?(message.message_id_hash) && id_table[message.message_id_hash].dummy?
          id_table[message.message_id_hash].message = message
          id_table[message.message_id_hash]
        else

          # Else:
          # - Create a new Container object holding this message;
          # - Index the Container by Message-ID in id_table.
          id_table[message.message_id_hash] = Container.new(message:)
        end

      # B. For each element in the message's References field:
      parent_container = nil
      message.reference_hashes.each do |reference|

        # - Find a Container object for the given Message-ID:
        #   - If there's one in id_table use that;
        #   - Otherwise, make (and index) one with a null Message.
        container = id_table[reference] || (id_table[reference] = Container.new(message: nil))

        # - Link the References field's Containers together in the order implied by the References
        #   header.
        #   - If they are already linked, don't change the existing links.
        #   - Do not add a link if adding that link would introduce a loop: that is, before
        #     asserting A->B, search down the children of B to see if A is reachable, and also
        #     search down the children of A to see if B is reachable. If either is already reachable
        #     as a child of the other, don't add the link.

        # If we have references A B C D, make D be a child of C, etc.
        # except if they have parents already.
        if !parent_container.nil? &&                            # not the top-most in references
           container.parent.nil? &&                             # not already linked
           !container.self_or_descendant?(parent_container) &&  # not a loop
           !parent_container.self_or_descendant?(container)     # not a loop
          parent_container.add_child(container)
        end

        parent_container = container
      end

      # C. Set the parent of this message to be the last element in References. Note that this
      # message may have a parent already: this can happen because we saw this ID in a References
      # field, and presumed a parent based on the other entries in that field. Now that we have the
      # actual message, we can be more definitive, so throw away the old parent and use this new
      # one. Find this Container in the parent's children list, and unlink it.

      # At this point `parent_container' is set to the container of the last element in the
      # references field. Make that be the parent of this container, unless doing so would introduce
      # a circularity.

      if !parent_container.nil? &&
         !current_container.self_or_descendant?(parent_container) &&
         !parent_container.self_or_descendant?(current_container)
        parent_container.add_child(current_container)
      end
    end

    # 2. Find the root set.
    root_set = id_table.filter_map { |_, container| container if container.root? }

    # 3. Discard id_table. We don't need it any more.
    id_table = nil

    # 4. Prune empty containers.
    root_set.map! do |root_container|
      prune_empty_containers(root_container)
    end

    root_set.compact!

    # 5, 6 removed to not group different threads with same subject into one.

    # 7. Now, sort the siblings.

    # At this point, the parent-child relationships are set. However, the sibling ordering has not
    # been adjusted, so now is the time to walk the tree one last time and order the siblings by
    # date, sender, subject, or whatever. This step could also be merged in to the end of step 4,
    # above, but it's probably clearer to make it be a final pass. If you were careful, you could
    # also sort the messages first and take care in the above algorithm to not perturb the ordering,
    # but that doesn't really save anything.

    root_set.map do |root_cont|
      root_cont.flatten.filter_map(&:message).sort_by(&:sort_field)
    end
  end

  # For root containers return a possibly modified copy of this container.
  # For non-root child containers return an index pointing to the next child of current parent.
  def prune_empty_containers(container)
    # Recursively walk all containers under the root set.

    # Traversing through children is in bottom-up direction because sometimes conditions for
    # parents are only met when we have processed their children.
    current_child = container.children.first
    until current_child.nil?
      next_child_index = prune_empty_containers(current_child)
      current_child = next_child_index.nil? ? nil : container.children[next_child_index]
    end

    if container.dummy? && container.children.empty? && container.parent.present?

      # A. If it is an empty container with no children, nuke it.

      next_child_index = container.parent.children.index(container)
      container.parent.remove_child(container)
      next_child_index

    elsif container.dummy? && container.children.empty? && container.root?

      # Return nil so later it is cleared from `root_set`.
      nil

    elsif container.dummy? && container.children.present? && container.parent.present?

      # B. If the Container has no Message, but does have children, remove this container but
      # promote its children to this level (that is, splice them in to the current child list.)

      # There's a present parent, we promote each child one level up.

      # `add_child` also removes the child from a previous parent and breaks a reference to
      # `container.children` so we use `dup` to not depend on broken references. Only comes up
      # when container has multiple children.
      container.children.dup.each do |child|
        container.parent.add_child(child)
      end

      # And destroy this container altogether.
      next_child_index = container.parent.children.index(container)
      container.parent.remove_child(container)
      next_child_index

    elsif container.dummy? && container.children.present? && container.root? &&
          container.children.size == 1

      # Do not promote the children if doing so would promote them to the root set -- unless
      # there is only one child, in which case, do.

      # This is a root container and there's only one child, replace the root container
      # with the only child.
      only_child = container.children.first
      only_child.parent = nil

      # This is our new root container, return it.
      only_child
    elsif !container.root?

      # Nothing to do, just point to the next container.
      container.parent.children.index(container) + 1
    elsif container.root?

      # Return our root container back.
      container
    else
      raise NotImplementedError, "Unreachable"
    end
  end
  # rubocop:enable Layout/EmptyLinesAroundBlockBody, Style/Next
end
