module <%= namespace_alone.camelize %>
  def self.table_name_prefix
    "<%= namespace_for_route %>"
  end
end
