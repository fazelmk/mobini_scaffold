# encoding : utf-8
module RansackSearchHelper
  def ransack_field(model_parm, attribute_name, f, namespace=nil, default_caption = nil, param = {})
    @model_name = model_parm
    model_name_for_translation = (namespace+"_"+@model_name unless namespace.blank?) || @model_name
    model_name_for_ransack = (namespace+"_"+@model_name unless namespace.blank?) || @model_name

    namespace += "/" unless namespace.blank?
    @model = "#{namespace}#{@model_name}".classify.constantize

    caption = default_caption
    if caption.blank? then
      caption = "activerecord.attributes.#{model_name_for_translation}.#{attribute_name}"
    end

    @field    = attribute_name

    begin
      @type_of_column = @model.attr_type(attribute_name).to_sym
    rescue
      @type_of_column = @model.attr_type(attribute_name[0..-4]).to_sym
    rescue
      @type_of_column = :other
    end
    #@field = model_name_for_translation + "_" + @field unless model_name_for_translation.blank?
    param[:default] = t("general.#{attribute_name}")
    text = '<div class="filter_box col-xs-12">'
    text += f.label @field, t(caption, param), :class => "control-label"
    text += ":&nbsp;&nbsp;"
    text2 = field_generator(attribute_name, f)
    return "" if text2.blank?
    text += text2
    text +='</div>'

    return text.html_safe
  end

  def field_generator(attribute_name, f)
    case @type_of_column
      when :date, :datetime, :time then
        return generate_date_search(f)

      when :boolean then
        return generate_boolean_search(f)

      when :string, :phone then
        return generate_string_search(f)

      when :integer, :float, :decimal, :references then
        return generate_numer_search(f)

      when  :price then
        return generate_price_search(f)

      when :file, :image then
        return generate_file_search(f)

      when :enum  then
        return generate_enum_search(f)

      else
        return generate_others_search(f)
    end
  end

  def generate_enum_search(f)
    enum = "Enum::#{@field.upcase}".constantize
    return f.select("#{@field}_eq".to_sym, options_for_select(enum.map { |k,v| [t("enums.#{@field.upcase}.#{v}"), k]}, @params_q["#{@field}_eq"]), { :include_blank => t("geleral.all") },{class: "form-control search_input"})
  end

  def generate_price_search(f)
    response = '<div class="input-prepend">'
    response += '<span class="add-on" rel="tooltip" title="' + t(:greater_than) + '">></span>'
    response += f.text_field((@field + "_cents_gteq").to_sym, :class => "#{align_attribute("integer")} filter-min form-control search_input #{@type_of_column}_mask")
    response += '</div>'
    response += '<div class="input-prepend">'
    response += '<span class="add-on" rel="tooltip" title="' + t(:smaller_than) + '"><</span>'
    response += f.text_field((@field + "_cents_lteq").to_sym, :class => "#{align_attribute("integer")} filter-max form-control search_input #{@type_of_column}_mask")
    response += '</div>'
  end

  def generate_others_search(f)
    response = ""
    response += f.text_field((@field + "_cont").to_sym, :class => "filter form-control search_input")
    return response
  end


  def generate_file_search(f)
    response = ""
    response += f.text_field((@field + "_file_name_cont").to_sym, :class => "filter form-control search_input")
    return response
  end

  def generate_numer_search(f)
    response = ""
    if @field[-3..-1] == "_id"
      btmodel = @model::ATTR_CLASS[@field]
      response += f.collection_select((@field + "_eq").to_sym, btmodel.sorted, :id, :caption_tag, { :include_blank => t("geleral.all") }, { :class => "form-control search_input_combobox" })
    elsif @field == "id" then
      response += f.text_field((@field + "_eq").to_sym, :class => "filter form-control search_input")
    else
      response += '<div class="input-prepend">'
      response += '<span class="add-on" rel="tooltip" title="' + t(:greater_than) + '">></span>'
      response += f.text_field((@field + "_gteq").to_sym, :class => "#{align_attribute("integer")} filter-min form-control search_input #{@type_of_column}_mask")
      response += '</div>'
      response += '<div class="input-prepend">'
      response += '<span class="add-on" rel="tooltip" title="' + t(:smaller_than) + '"><</span>'
      response += f.text_field((@field + "_lteq").to_sym, :class => "#{align_attribute("integer")} filter-max form-control search_input #{@type_of_column}_mask")
      response += '</div>'
    end
    return response
  end

  def generate_string_search(f)
    response = ""
    response += f.text_field((@field + "_cont").to_sym, :class => "filter form-control search_input #{@type_of_column}_mask")
    return response
  end

  def generate_boolean_search(f)
    response = ""
    # Specify a default value (false) in rails migration
    response += f.select((@field + "_eq").to_sym, options_for_select([[t("all"),nil],[t("true"),"true"],[t("false"),"false"]], selected: @params_q[(@field+"_eq")] || nil),{}, { :class => "form-control search_input_combobox" })
  end

  def generate_date_search(f)
    if @type_of_column == :datetime
      dt = 2
    elsif @type_of_column == :date
      dt = 1
    else
      dt = 0
    end

    response = ""
    # Greater than
    if dt == 0
      response += '<div class="input-prepend input-append input-' + @type_of_column.to_s + '">'
      response += '<span class="add-on">></span>'
      response += f.text_field (@field + "_gteq").to_sym, {:value => (begin @params_q[(@field + "_gteq")] rescue '' end), class: "time_mask form-control search_input"}
      response += '</div>'
      response += '<div class="input-prepend input-append input-' + @type_of_column.to_s + '">'
      response += '<span class="add-on"><</span>'
      response += f.text_field (@field + "_lteq").to_sym, {:value => (begin @params_q[(@field + "_lteq")] rescue '' end), class: "time_mask form-control search_input"}
      response += '</div>'

    elsif dt == 1
      response += '<div class="input-prepend input-append input-' + @type_of_column.to_s + '">'
      response += '<span class="add-on">></span>'
      response += f.text_field (@field + "_gteq").to_sym, {:value => (begin @params_q[(@field + "_gteq")] rescue '' end), class: "date_mask form-control search_input"}
      response += '</div>'
      response += '<div class="input-prepend input-append input-' + @type_of_column.to_s + '">'
      response += '<span class="add-on"><</span>'
      response += f.text_field (@field + "_lteq").to_sym, {:value => (begin @params_q[(@field + "_lteq")] rescue '' end), class: "date_mask form-control search_input"}
      response += '</div>'
    else
      response += '<div class="input-prepend input-append input-' + @type_of_column.to_s + '">'
      response += '<span class="add-on">></span>'
      response += f.text_field (@field + "_gteq").to_sym, {:value => (begin @params_q[(@field + "_gteq")] rescue '' end), class: "datetime_mask form-control search_input"}
      response += '</div>'
      response += '<div class="input-prepend input-append input-' + @type_of_column.to_s + '">'
      response += '<span class="add-on"><</span>'
      response += f.text_field (@field + "_lteq").to_sym, {:value => (begin @params_q[(@field + "_lteq")] rescue '' end), class: "datetime_mask form-control search_input"}
      response += '</div>'
    end

    return response
  end
end
