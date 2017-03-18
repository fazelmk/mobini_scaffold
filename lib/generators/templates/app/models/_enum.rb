<%- attr_to_migration.select{|a| a[:type] == "enum"}.each do |att| -%>
<%- name = att[:name]
    type = att[:type]
    unless att[:options].blank?
      opc_splt = att[:options].split(",")
      opc_str = opc_splt.select{|o| o.include? "enum"}.first.split(":")[1].strip
      opc_array = eval opc_str.gsub(";", ",")
    end
    opc_array ||= nil
-%>
<%- unless opc_array.blank? || File.read("app/models/enum.rb").include?("#{name.upcase}") -%>
    <%= name.upcase %> = {nil => "nil", <%= opc_array.each_with_index.map{|x,i| "#{i+1} => \"#{x}\""}.join(", ") %>}
<%- end -%>
<%- end -%>
