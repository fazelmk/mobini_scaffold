# encoding : utf-8
module MobinisHelper
  def image_types
    return ['image/jpg','image/jpeg','image/pjpeg','image/png','image/x-png','image/gif']
  end

  def file_types
    return ['application/pdf','application/msword','applicationvnd.ms-word','applicaiton/vnd.openxmlformats-officedocument.wordprocessingm1.document','application/msexcel','application/vnd.ms-excel','application/vnd.openxmlformats-officedocument.spreadsheetml.sheet','application/mspowerpoint','application/vnd.ms-powerpoint','application/vnd.openxmlformats-officedocument.presentationml.presentation','text/plain','text/csv']
  end

  def class_to_att(class_name)
    return class_name.underscore.gsub("/","_")
  end

  def visible_column(model_name, field_name)
    return current_user.visible_fields.select {|f| f.model=="#{model_name}" && f.field=="#{field_name}"}.size == 1
  end

  def show_value(value,type,field_name=nil,model_class_name=nil, format = :short)
    return case type
      when "date","datetime"
        value.blank? ? "" : l(value, format: format)

      when "image"
        value

      when "enum"
        I18n.t("enums.#{field_name.upcase}.#{("Enum::#{field_name.upcase}".constantize)[value]}")

      when "file"
        value

      when "price"
        humanized_money_with_symbol value

      when "references"
        unless value.blank?
          (model_class_name.constantize)::ATTR_CLASS[field_name].find_by_id(value).try(:caption_tag)
        else
          t("general.not_informed")
        end

      when "boolean"
        t(value || 'false')

      else
        value
    end
  end

  def align_attribute(attribute_type)
    return case attribute_type
       when "integer", "float", "numeric", "decimal" then
         "ar"
       when "boolean", "date", "datetime", "timestamp", "time" then
         "ac"
       else
         "al"
     end
  end

  def glink_to icon, text, url, options={}
    link_to ("<span class='glyphicon glyphicon-#{icon}''></span> #{text}").html_safe, url, method: options[:method], data: options[:data], :class => options[:class] || "btn btn-default"
  end

  def sorting_header(model_name, attr_name, attr_type, namespace=nil, param = {})
    attr    = nil
    sort    = nil

    if not params[:sorting].blank? then
      attr = params[:sorting][:attribute]
      sort = params[:sorting][:sorting]
    end

    if attr_type == "price" then
      attribute = attr_name.downcase + "_cents"
    else
      attribute = attr_name.downcase
    end

    attr    = attr.to_s.downcase
    sortstr = sort.to_s.downcase
    opposite_sortstr = ""
    csort = '' # <i class="icon-stop"></i>
    if attribute == attr then
      if sortstr == "asc" then
        csort = '<span class="glyphicon glyphicon-chevron-up"></span>'
        opposite_sortstr = "desc"
      elsif sortstr == "desc" then
        csort = '<span class="glyphicon glyphicon-chevron-down"></span>'
        opposite_sortstr = "asc"
      end
    else
      opposite_sortstr = "asc"
    end
    namespace_route = ""
    namespace_route = namespace + '_' unless namespace.blank?
    #default caption added
    param[:default] = t("general.#{attr_name}")
    caption = t("activerecord.attributes.#{namespace_route}#{model_name}.#{attr_name.downcase.gsub("_id", "")}", param)
    if model_name.tableize == model_name.underscore
      strpath = namespace_route+model_name.tableize + "_index_path"
    else
      strpath = namespace_route+model_name.tableize + "_path"
    end

    return link_to(
        "#{csort} #{caption}".html_safe,
        eval(strpath) + "?" +
            CGI.unescape({:sorting => {:attribute => attribute,:sorting => opposite_sortstr}}.to_query)
    ).html_safe
  end

  def clean_params
    params.delete :search
  end
end
