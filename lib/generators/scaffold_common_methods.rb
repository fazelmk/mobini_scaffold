module ScaffoldCommonMethods
  require 'erb'
  private
  #############
  # Namespace
  #############

  def namespaced?
    !namespace_alone.blank?
  end

  def namespace_for_class
    str = namespace_alone
    str = str.camelcase + '::' if not str.blank?
    return str.to_s
  end

  def namespace_for_route
    str = namespace_alone
    str = str.downcase + '_' if not str.blank?
    return str.to_s
  end

  def namespace_for_url
    str = namespace_alone
    str = str.downcase + '/' if not str.blank?
    return str.to_s
  end

  def namespace_for_translate
    str = namespace_alone
    str = str.downcase + '.' if not str.blank?
    return str.to_s
  end

  def namespace_alone
    begin
      return model_namespace.to_s
    rescue
      return options[:namespace].to_s.downcase
    end
  end

  def render_partial(path)
    source  = File.expand_path(find_in_source_paths(path.to_s))
    result = ERB.new(::File.binread(source), nil, '-').result(binding)
    return result
  end

  ################
  #Options Input
  ################
  def have_export_or_import?
    have_export? || have_import?
  end

  def have_export?
    return options[:without_export].blank? ? true : false
  end

  def have_import?
    return options[:without_import].blank? ? true : false
  end

  def replace_shared?
    return options[:replace_shared].blank? ? false : true
  end

  def without_locales?
    return options[:without_locales].blank? ? false : true
  end

  def admin_only?
    return options[:admin_only].blank? ? false : true
  end

  ############
  # Models
  ############

  def model_class
    namespace_for_class+singular.camelize
  end

  def model_pluralize
    plural.camelize
  end

  ############
  #   URLS
  ###########
  def route_url
    namespace_for_url+plural
  end

  def model_url
    namespace_for_url+singular
  end

  def plural_model_url
    namespace_for_url+plural
  end

  ############
  # Table
  ############
  def singular
    model.underscore
  end

  def plural
    model.tableize
  end

  alias_method :model_file, :singular
  alias_method :model_wthout_namespace, :singular
  alias_method :model_table_wthout_namespace, :plural

  def plural_table_name
    namespace_for_route+plural
  end

  def singular_table_name
    namespace_for_route+singular
  end

  def index_route
    if singular_table_name == plural_table_name
      return singular_table_name+"_index"
    else
      return plural_table_name
    end
  end

  def available_views
    %w(index edit show _show_fields new _form _form_fields import _import_fields _search)
  end

  def att_name(att)
    return att.gsub "/","_"
  end

  def att_class(att,attribute)
    if !attribute.blank? and attribute.attr_options.select{|k,v| k == "class_name"}.size > 0
      return ", class_name: '#{attribute.attr_options.select{|k,v| k == "class_name"}.first[1].classify}'"
    else
      if !att.index("/").blank?
        return ", class_name: '#{att.classify}'"
      else
        return ""
      end
    end
  end

  def fk(att, attribute)
    if ((!attribute.blank? and attribute.attr_options.select{|k,v| k == "class_name"}.size > 0) or !att.index("/").blank?)
      return ", foreign_key: '#{att_name(att)}_id'"
    end
    return ""
  end

  def attr_class_for_form(att,attribute)
    if attribute.attr_options.select{|k,v| k == "class_name"}.size > 0
      return attribute.attr_options.select{|k,v| k == "class_name"}.first[1].classify
    end
    return att.classify
  end

  def match_att(str)
    return str.match /(?<name>[a-zA-Z0-9_\/]+):(?<type>[a-zA-Z0-9_]+)({(?<options>.*)})?(:(?<index>.*))?/
  end

  def attributes
    # https://raw.github.com/rails/rails/master/railties/lib/rails/generators/generated_attribute.rb
    require 'rails/generators/generated_attribute'

    return @myattributes.map{ |a|
      at = match_att(a)
      attr = at[:name]
      type = at[:type]
      index = false
      index = at[:index] if not at[:index].blank?
      opc = {}
      unless at[:options].blank?
        opc_splt = at[:options].split(",")
        opc_splt.each {|x| opc[x.split(":")[0].strip] = x.split(":")[1].strip}
      end
      Rails::Generators::GeneratedAttribute.new(attr, type.to_sym,index,opc)
    }
  end

  def attr_to_rails_attr
    newmyattributes = []
    @myattributes.each{ |attr|
      attribute_match = match_att(attr)
      a = attribute_match[:name]
      t = attribute_match[:type]

      newmyattributes << [a, t].join(":")
    }

    return newmyattributes
  end

  def attr_to_migration
    newmyattributes = []
    @myattributes.each{ |attr|
      attribute_match = match_att(attr)
      newmyattributes << attribute_match
    }

    return newmyattributes
  end

  def attributes_with_index
    attributes.select { |a| !a.reference? && a.has_index?}
  end

  def attributes_without_type
    newmyattributes = []
    @myattributes.each{ |attr|
      att = match_att(attr)
      a = att[:name]
      t = att[:type]
      if ['references', 'reference'].include?(t) then
        a = a + '_id'
      end

      newmyattributes << a
    }

    return newmyattributes
  end
end
