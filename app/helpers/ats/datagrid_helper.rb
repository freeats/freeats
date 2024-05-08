# frozen_string_literal: true

module ATS::DatagridHelper
  def ats_datagrid_render_row(grid, asset, options = {})
    render(
      partial: "datagrid/row",
      locals: {
        grid:,
        asset:,
        options:
      }
    )
  end
end
