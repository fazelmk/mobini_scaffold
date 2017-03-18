class Create<%= namespace_alone.camelize %><%= model_pluralize %> < ActiveRecord::Migration
  def self.up
    create_table :<%= plural_table_name %> do |t|
<%- attr_to_migration.each do |att| -%>
<%- name = att[:name]
    type = att[:type]
    unless att[:options].blank?
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
      t.attachment :<%= name %>
<%- elsif type == "price" -%><%= opc_str %>
      t.money :<%= name %>
<%- elsif type == "wday" -%>
      t.integer :<%= name %><%= opc_str %>
<%- elsif (type == "reference" || type == "references") && class_name_opc != true -%>
      t.references :<%= att_name(name) %><%= opc_str %>
<%- elsif (type == "reference" || type == "references") && class_name_opc == true -%>
      t.integer :<%= att_name(name) %>_id, index: true<%= opc_str %>
<%- elsif type.in? ["time", "phone"] -%>
      t.string :<%= name %><%= opc_str %>
<%- elsif (type == "enum") -%>
      t.integer :<%= name %><%= opc_str %>
<%- else -%>
      t.<%= type %> :<%= name %><%= opc_str %>
<%- end -%>
<%- end -%>
      t.timestamps
    end
<% attributes_with_index.each do |attribute| -%>
    add_index :<%= plural_table_name %>, :<%= attribute.index_name %><%= attribute.inject_index_options %>
<% end -%>
  end

  def self.down
    drop_table :<%= plural_table_name %>
  end
end
