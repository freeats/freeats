# frozen_string_literal: true

module ApplicationHelper
  PRIORITY_COLORS = {
    "low" => "code-green",
    "medium" => "code-yellow",
    "high" => "code-red"
  }.freeze

  def options_for_priority(collection, selected_value = nil)
    options =
      collection.map do |_, value|
        {
          text: value.humanize,
          value:,
          color: PRIORITY_COLORS[value],
          selected: selected_value == value
        }
      end
    safe_join(
      options.map do |option|
        tag.option(value: option[:value], selected: option[:selected]) do
          tag.div(class: "d-inline-flex align-items-center gap-2") do
            safe_join [
              render(IconComponent.new(:circle, icon_type: :filled, class: option[:color])),
              option[:text]
            ]
          end
        end
      end
    )
  end

  def ats_title(page_title)
    content_for(:title) { "#{page_title} | FreeATS" }
  end

  def grid_filter(form:, grid:, filter:)
    if filter.options.dig(:autocomplete, :type) == :multiple_locations
      options =
        Location
        .where(id: grid.public_send(filter.name))
        .flat_map { compose_location_option_for_select(_1) }

      render PillSelectComponent.new(
        "#{grid.model_name.param_key}[#{filter.name}]",
        placeholder: filter.options[:placeholder],
        remote: {
          search_url: fetch_locations_api_v1_locations_path(
            types: filter.options.dig(:autocomplete, :location_types).join(","),
            q: "QUERY"
          ),
          options:
        }
      )
    elsif filter.options[:checkboxes].present?
      form.datagrid_filter(filter)
    elsif filter.options[:select].present?
      compose_select_component(filter:, grid:)
    else
      form.datagrid_filter(
        filter,
        class: "form-control",
        **(filter.options.slice(:placeholder, :type) || {})
      )
    end
  end

  def compose_location_option_for_select(location, selected: true)
    return unless location

    [{
      text: location.short_name,
      value: location.id,
      selected:
    }]
  end

  def short_time_ago_in_words(time)
    distance_of_time_in_words(time, Time.zone.now, scope: "datetime.distance_in_words.short")
  end

  def add_default_sorting(grid_params, column, direction = :asc)
    return grid_params if grid_params&.key?(:order)

    grid_params ||= {}
    grid_params[:order] = column
    grid_params[:descending] = direction == :desc
    grid_params
  end

  def link_to_with_copy_popover_button(content, href, data: {}, **)
    link_to(
      content,
      href,
      target: ("_blank" if data[:turbo_frame].blank?),
      data: {
        controller: "copy-to-clipboard",
        copy_to_clipboard_link_with_popover_value: true
      }.merge(data),
      **
    )
  end

  def drag_and_drop_tooltip
    t("core.drag_and_drop_tooltip")
  end

  def compose_actor_account_name(event)
    if event.actor_account_id.blank?
      "FreeATS"
    else
      tag.b(event.actor_account.name)
    end
  end

  def unescape_link_tags(html)
    # Captures everything between closest openings and closings of <a> tag and unescapes it.
    html.gsub(/(<a(?:(?!<a|>)[\s\S])*>)/) { CGI.unescape(Regexp.last_match(1)) }
  end

  def render_deactivate_partial(model)
    render partial: "ats/teams/deactivate", locals: { account: model }
  end

  def public_recaptcha_v3_verified?(recaptcha_v3_score:)
    recaptcha_v3_score.to_f >= RecaptchaV3::MIN_SCORE
  end

  def public_recaptcha_v2_verified?(recaptcha_v2_response:)
    Recaptcha.verify_via_api_call(recaptcha_v2_response, {})
  end

  private

  def compose_select_component(grid:, filter:)
    filter_select_value = filter.options[:select]

    # Used `send` because we may call the protected Datagrid method when processing columns filter.
    select_options =
      case filter_select_value
      when Proc then filter_select_value.call
      when Symbol then grid.__send__(filter_select_value)
      else filter_select_value
      end

    selected_values = Array(grid.public_send(filter.name)).map(&:to_s)

    # The `value` could be integer or symbol.
    # The `value` as symbol is used for the Datagrid columns filter.
    options = select_options.map do |text, value|
      value = value.to_s
      { text:, value:, selected: value.in?(selected_values) }
    end

    select_params = {
      placeholder: filter.options[:placeholder],
      include_blank: filter.options[:include_blank],
      local: { options: }
    }.compact
    name = "#{grid.model_name.param_key}[#{filter.name}]"
    if filter.options[:multiple]
      render MultipleSelectComponent.new(name, **select_params)
    else
      render SingleSelectComponent.new(name, **select_params)
    end
  end
end
