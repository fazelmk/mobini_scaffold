class <%= @migration_name %> < ActiveRecord::Migration
  def change
<%- attr_to_migration.each do |att| -%>
<%- name = att[:name]
    type = att[:type]
    if not att[:options].blank?
      opc_splt = att[:options].split(",")
      opc = {}
      class_name_opc = true if opc_splt.select{|o| o.include? "class_name"}.size > 0
      opc_splt.select{|o| !o.include?("enum") && !o.include?("class_name")}.each {|x| opc[x.split(":")[0].strip] = x.split(":")[1].strip}
      opc_map = opc.map{|k,v| ", #{k}: #{v}"} if opc.size > 0
      opc_str = opc_map.join("") unless opc_map.blank?
    end
    opc_str ||= ""
-%>
<%- if type == "file" || type == "image" -%>
    add_column :<%= plural_table_name %>, :<%= name %>_file_name, :string
    add_column :<%= plural_table_name %>, :<%= name %>_content_type, :string
    add_column :<%= plural_table_name %>, :<%= name %>_file_size, :integer
    add_column :<%= plural_table_name %>, :<%= name %>_updated_at, :datetime
<%- elsif type == "price" -%>
    add_money :<%= plural_table_name %>, :<%= name %><%= opc_str %>
<%- elsif (type == "reference" || type == "references") && class_name_opc != true -%>
    add_reference :<%= plural_table_name %>, :<%= att_name(name) %>, index: true<%= opc_str %>
<%- elsif (type == "reference" || type == "references") && class_name_opc == true -%>
    add_column :<%= plural_table_name %>, :<%= att_name(name) %>_id, :integer, index: true<%= opc_str %>
<%- elsif (type.in? ["time","phone"]) -%>
    add_column :<%= plural_table_name %>, :<%= name %>, :string<%= opc_str %>
<%- elsif (type == "enum") -%>
    add_column :<%= plural_table_name %>, :<%= name %>, :integer<%= opc_str %>
<%- else -%>
    add_column :<%= plural_table_name %>, :<%= name %>, :<%=type%> <%= opc_str %>
<%- end -%>
<%- end -%>
<% attributes_with_index.each do |attribute| -%>
    add_index :<%= plural_table_name %>, :<%= attribute.index_name %><%= attribute.inject_index_options %>
<% end -%>
  end
end
