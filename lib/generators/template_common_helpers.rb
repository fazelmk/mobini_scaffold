module TemplateCommonHelpers
  require 'erb'
  private
  def copy_file_unless_exists template, destination

    template = find_in_source_paths(template)

    exists = File.exist?(destination)

    #puts "#{template} - #{destination} - exists #{exists} identical #{identical}  #{File.mtime(template)} #{File.mtime(destination)}"
    copy_file template,  destination unless exists && !replace_shared?
  end

  #used to replace string in text
  def sub_file(file_path, search_text, replace_text, behavior)
    if behavior == :invoke
     search = search_text
     replace = replace_text
    else
      search = replace_text
      replace = search_text
    end

    path = File.join(Rails.root,file_path)

    if File.exist?(path)
      file_content = File.read(path)

      if ((file_content.include?(search) && search != "gem 'nested_form'") || (search == "gem 'nested_form'" && file_content.include?(search) && !file_content.include?(replace)))
        content = file_content.sub(/(#{Regexp.escape(search)})/mi, replace)
        File.open(path, 'wb') { |file| file.write(content) }
      end
    end
  end
  #################

  ## ENUMS
  def enum_helper
    attributes.select{|a| a.type == :enum }.each do |att|
      inject_into_file("app/models/#{model_url}.rb","\n\t"+"def #{att.name}_desc\n\t\t"+"I18n.t(\"enums.#{att.name.upcase}.\#{Enum::#{att.name.upcase}[#{att.name}]}\")\n\tend", :after => "######### DON`T REMOVE - ENUMS ###################") if File.exists?("app/models/#{model_url}.rb")
    end
    if attributes.select{|a| a.type == :enum }.count > 0
      inject_into_file("config/locales/pt-BR/enums.yml","\n"+render_partial("app/translation/_enum.yml")+"\n", :after => "enums:")
      inject_into_file("app/models/enum.rb","\n"+render_partial("app/models/_enum.rb")+"\n", :after => "class Enum")
    end
  end

  ##generate model and relations
  def generate_model_helper
    dirs = ['app', 'models', namespace_alone].compact
    empty_directory File.join(dirs) unless File.directory?(File.join(dirs.flatten))
    template "app/models/model.rb", File.join([dirs, "#{model_file}.rb"].flatten)
    template "app/models/namespace.rb", File.join([['app', 'models'].compact, "#{namespace_alone}.rb"].flatten) unless namespace_alone.blank?
  end

  def generate_belongs_and_has_many_helper
    attributes.select(&:reference?).each do |attribute|
      inject_into_file("app/models/#{model_url}.rb","\n\t"+"belongs_to :#{att_name(attribute.name)}#{att_class(attribute.name,attribute)}#{fk(attribute.name,attribute)}"+((', polymorphic: true' if attribute.polymorphic?) || ""), :after => "######### DON`T REMOVE - belongs_to ##############")  if File.exists?("app/models/#{model_url}.rb")
      unless attribute.polymorphic?
        if attribute.attr_options.select{|k,v| k == "class_name"}.size > 0
          inject_into_file("app/models/#{attribute.attr_options.select{|k,v| k == "class_name"}.first[1].underscore}.rb", "\n\t"+'has_many :'+attribute.name+att_class(attribute.name,attribute)+fk(attribute.name,attribute)+', dependent: :restrict_with_exception', :after => "######### DON`T REMOVE - has_many ################") if File.exists?("app/models/#{attribute.attr_options.select{|k,v| k == "class_name"}.first[1].underscore}.rb")
        else
          inject_into_file("app/models/#{attribute.name}.rb", "\n\t"+'has_many :'+plural_table_name+att_class(model_class.underscore,attribute)+fk(attribute.name,attribute)+', dependent: :restrict_with_exception', :after => "######### DON`T REMOVE - has_many ################") if File.exists?("app/models/#{attribute.name}.rb")
        end
      end
    end
  end

  def generate_permited_attributes
    attributes.each do |att|
      if att.type == :reference || att.type == :references
        if File.exists?("app/models/#{model_url}.rb")
          inject_into_file("app/models/#{model_url}.rb", ":#{att_name(att.name)}_id, ", :after => "def self.permitted_attributes\n    return ")
          inject_into_file("app/models/#{model_url}.rb", "\"#{att_name(att.name)}_id\", ", :after => "def self.attributes_allowed_in_index
    return ")
        end
      elsif att.type == :price
        if File.exists?("app/models/#{model_url}.rb")
          inject_into_file("app/models/#{model_url}.rb", "\n\tmonetize :#{att.name}_cents", :after => "######### DON`T REMOVE - price ###################")
        end
        if File.exists?("app/models/#{model_url}.rb")
          inject_into_file("app/models/#{model_url}.rb", ":#{att.name}_cents, ", :after => "def self.permitted_attributes\n    return ")
          inject_into_file("app/models/#{model_url}.rb", "\"#{att.name}_cents\", ", :after => "def self.attributes_allowed_in_index
    return ")
        end
      else
        if File.exists?("app/models/#{model_url}.rb")
          inject_into_file("app/models/#{model_url}.rb", ":#{att.name}, ", :after => "def self.permitted_attributes\n    return ")
          inject_into_file("app/models/#{model_url}.rb", "\"#{att.name}\", ", :after => "def self.attributes_allowed_in_index
    return ")
        end
      end
    end
  end

  def generate_attachment
    attributes.select{|att| att.type == :file || att.type == :image }.each do |attribute|
        types = attribute.type == :file ? "'file/txt','file/csv','file/xls', 'file/pdf'" : "'image/jpeg', 'image/png'"
        text = "\n\thas_attached_file :#{attribute.name}"
        text +=', :styles => { :small => "150x150>" },' unless attribute.type == :file
        text +="\n\t\t\t:url  => '"+"/assets/#{model_url}/#{attribute.name}/:id/:style/:basename.:extension"+"',"
        text +="\n\t\t\t:default_url => ''," unless attribute.type == :image
        text +="\n\t\t\t:path => '"+":rails_root/app/assets/#{model_url}/#{attribute.name}/:id/:style/:basename.:extension"+"'"
        text +="\n\t\tvalidates_attachment_presence :#{attribute.name}"
        text +="\n\t\tvalidates_attachment_size :#{attribute.name}, :less_than => 5.megabytes"
        text +="\n\t\tvalidates_attachment_content_type :#{attribute.name}, :content_type => [#{types}]\n"
        inject_into_file("app/models/#{model_url}.rb",text, after: "############# DON`T REMOVE - file ################") if File.exists?("app/models/#{model_url}.rb")
      end
  end

  def generate_add_attr
    path = File.join(Rails.root,"app/models/#{model_url}.rb")
    if File.exist?(path)
      #add atributes to ATTR_TYPE.
      text = ""
      primeiro = true
      attributes.each{ |attr|
        text += "\"#{att_name(attr.name)}\" => \"#{attr.type}\""
        unless File.read(path).include?("ATTR_TYPE = {}") && primeiro
          text+= ", "
          primeiro = false
        end
      }
      inject_into_file("app/models/#{model_url}.rb",text, :after => "ATTR_TYPE = {") if File.exists?("app/models/#{model_url}.rb")

      #Add reference attributes to ATTR_CLASS
      text = ""
      primeiro = true
      attributes.select(&:reference?).each{ |attr|
        text += "\"#{att_name(attr.name)}_id\" => #{attr_class_for_form(attr.name,attr)}"
        unless File.read(path).include?("ATTR_CLASS = {}") && primeiro
          text+= ", "
          primeiro = false
        end
      }
      inject_into_file("app/models/#{model_url}.rb",text, :after => "ATTR_CLASS = {") if File.exists?("app/models/#{model_url}.rb")
    end
  end

  ##generate translation
  def generate_translation_helper
    #translation
    pt_BR = ['config','locales','pt-BR', 'model_translation',"#{singular_table_name}.yml"].compact
    if (!without_locales? || !File.exist?(File.join(pt_BR)))
      template "app/translation/pt-BR.yml", File.join(pt_BR)
    end
  end

  ##Generate create table migration
  def generate_table_helper
    source  = File.expand_path(find_in_source_paths("app/migrations/create_table_migration.rb"))
    destination = File.expand_path("db/migrate/create_#{plural_table_name}.rb", self.destination_root)

    migration_dir = File.dirname(destination)
    @migration_number  = Time.now.utc.strftime("%Y%m%d%H%M%S")
    @migration_file_name  = File.basename(destination, '.rb')
    @migration_class_name = @migration_file_name.camelize

    context = instance_eval('binding')

    dir, base = File.split(destination)
    numbered_destination = File.join(dir, ["%migration_number%", base].join('_'))

    create_migration numbered_destination, nil, {} do
      ERB.new(::File.binread(source), nil, '-', '@output_buffer').result(context)
    end
  end

  def generate_migration_helper
    source  = File.expand_path(find_in_source_paths("app/migrations/add_fields_migration.rb"))
    destination = File.expand_path("db/migrate/#{@migration_name.underscore}.rb", self.destination_root)

    migration_dir = File.dirname(destination)
    @migration_number  = Time.now.utc.strftime("%Y%m%d%H%M%S")
    @migration_file_name  = File.basename(destination, '.rb')
    @migration_class_name = @migration_file_name.camelize

    context = instance_eval('binding')

    dir, base = File.split(destination)
    numbered_destination = File.join(dir, ["%migration_number%", base].join('_'))

    create_migration numbered_destination, nil, {} do
      ERB.new(::File.binread(source), nil, '-', '@output_buffer').result(context)
    end
  end

  def generate_view_migration_helper
    commonpath = "app/views/#{plural_model_url}/"
    # Form
    inject_into_file("#{commonpath}_form_fields.html.erb", render_partial("app/views/partials/_form_field.html.erb"), :before => "<!-- DON'T REMOVE - USED TO ADD NEW FIELDS -->" ) if File.exists?("#{commonpath}_form_fields.html.erb")
    # Show
    inject_into_file("#{commonpath}_show_fields.html.erb", render_partial("app/views/partials/_show_field.html.erb"), :before => "<!-- DON'T REMOVE - USED TO ADD NEW FIELDS -->" ) if File.exists?("#{commonpath}_show_fields.html.erb")
    # Import
    inject_into_file("#{commonpath}_import_fields.html.erb", render_partial("app/views/partials/_import_field.html.erb"), :before => "<!-- DON'T REMOVE - USED TO ADD NEW FIELDS -->" ) if File.exists?("#{commonpath}_import_fields.html.erb")
  end

  def generate_nested_views_helper
    namespacedirs = ["app", "views", namespace_alone].compact
    dirs = [namespacedirs, model_table_wthout_namespace]
    empty_directory File.join(namespacedirs) unless File.directory?(File.join(namespacedirs.flatten))
    empty_directory File.join(dirs) unless File.directory?(File.join(dirs.flatten))

    view_path = File.join([dirs, "_form_fields.html.erb"].flatten)
    template_path   = File.join(["app", "views", "_form_fields.html.erb"].flatten)
    template template_path, view_path

    view_path = File.join([dirs, "_show_fields.html.erb"].flatten)
    template_path   = File.join(["app", "views", "_show_fields.html.erb"].flatten)
    template template_path, view_path

    view_path = File.join([dirs, "_import_fields.html.erb"].flatten)
    template_path   = File.join(["app", "views", "_import_fields.html.erb"].flatten)
    template template_path, view_path
  end

  def generate_nested_partials_helper
    namespacedirs = ["app", "views", namespace_alone].compact
    dirs = [namespacedirs, model_table_wthout_namespace]
    empty_directory File.join(namespacedirs) unless File.directory?(File.join(namespacedirs.flatten))
    empty_directory File.join(dirs) unless File.directory?(File.join(dirs.flatten))

    view_path = File.join([dirs, "_nested_form.html.erb"].flatten)
    template_path   = File.join(["app", "views", "partials", "_nested_form.html.erb"].flatten)
    template template_path, view_path

    view_path = File.join([dirs, "_nested_show.html.erb"].flatten)
    template_path   = File.join(["app", "views", "partials", "_nested_show.html.erb"].flatten)
    template template_path, view_path

    view_path = File.join([dirs, "_nested_import.html.erb"].flatten)
    template_path   = File.join(["app", "views", "import.html.erb"].flatten)
    template template_path, view_path
  end

  def generate_associate_nested_views_helper
    nested_form_file = File.join([namespace_alone, model_table_wthout_namespace, "nested_form.html.erb"].compact.flatten)
    if File.exists?("app/views/#{parent_model.pluralize}/_form.html.erb")
      inject_into_file("app/views/#{parent_model.pluralize}/_form.html.erb","\n<%= render '#{nested_form_file}', parent_form: f %>", after: "<!-- DON'T REMOVE - USED TO ADD NESTED MODELS -->")
      sub_file("app/views/#{parent_model.pluralize}/_form.html.erb", '<%= form_for(', '<%= nested_form_for(', behavior)
    elsif File.exists?("app/views/#{parent_model.pluralize}/_nested_form.html.erb")
      inject_into_file("app/views/#{parent_model.pluralize}/_nested_form.html.erb","\n<%= render '#{nested_form_file}', parent_form: f %>", after: "<!-- DON'T REMOVE - USED TO ADD NESTED MODELS -->")
    end

    nested_show_file = File.join([namespace_alone, model_table_wthout_namespace, "nested_show.html.erb"].compact.flatten)
    inject_into_file("app/views/#{parent_model.pluralize}/show.html.erb","\n<%= render '#{nested_show_file}', parent: @#{parent_model.underscore.gsub("/","_")} %>", after: "<!-- DON'T REMOVE - USED TO ADD NESTED MODELS -->") if File.exists?("app/views/#{parent_model.pluralize}/show.html.erb")

    # Parent Import
    nested_import_file = File.join([namespace_alone, model_table_wthout_namespace, "nested_import.html.erb"].compact.flatten)
    if File.exists?("app/views/#{parent_model.pluralize}/_form.html.erb")
      inject_into_file("app/views/#{parent_model.pluralize}/import.html.erb", "\n<%= render '#{nested_import_file}', parent_model_class: '#{parent_model.classify}' %>\n", :before => "<!-- DON'T REMOVE - USED TO ADD NESTED IMPORT -->" ) if File.exists?("app/views/#{parent_model.pluralize}/import.html.erb")
    elsif File.exists?("app/views/#{parent_model.pluralize}/_nested_form.html.erb")
      inject_into_file("app/views/#{parent_model.pluralize}/_nested_import.html.erb", "\n<%= render '#{nested_import_file}', parent_model_class: '#{parent_model.classify}' %>\n", :before => "<!-- DON'T REMOVE - USED TO ADD NESTED IMPORT -->" ) if File.exists?("app/views/#{parent_model.pluralize}/import.html.erb")
    end
  end

  def generate_add_parent_model_to_inport_view_helper
    # Import field
    commonpath = "app/views/#{plural_model_url}/"
    inject_into_file("#{commonpath}_import_fields.html.erb", render_partial("app/views/partials/_import_field.html.erb"), :before => "<!-- DON'T REMOVE - USED TO ADD NEW FIELDS -->" ) if File.exists?("#{commonpath}_import_fields.html.erb")
  end

  def generate_add_parent_to_translation_helper
    inject_into_file("config/locales/pt-BR/model_translation/#{singular_table_name}.yml", "        #{att_name(parent_model)}_id:\n        #{att_name(parent_model)}_id_import:\n", :before => "######## DON'T REMOVE - ADD Fields To Translate ###############") if File.exists?("config/locales/pt-BR/model_translation/#{singular_table_name}.yml")
  end

  def generate_nested_model_options_helper
    ######## accepts_nested_attributes_for
     inject_into_file("app/models/#{parent_model}.rb", "\n\taccepts_nested_attributes_for :#{plural_table_name}, :allow_destroy => true", :after => "########### DON`T REMOVE - nested ################") if File.exists?("app/models/#{parent_model}.rb")

    ############ permitted_attributes
    inject_into_file("app/models/#{parent_model}.rb", ", #{plural_table_name}_attributes: [:id, "+"#{model_class}"+".permitted_attributes, :_destroy]", :before => "### DON'T REMOVE - Used to add Attr to Nested models ###") if File.exists?("app/models/#{parent_model}.rb")

    ######## NESTED_MODEL#######
    if File.exists?("app/models/#{parent_model}.rb")
      if File.read("app/models/#{parent_model}.rb").include?("NESTED_CHILD_MODELS = []")
        inject_into_file("app/models/#{parent_model}.rb", "\"#{model_class}\"", :after => "NESTED_CHILD_MODELS = [")
      else
        unless File.read("app/models/#{parent_model}.rb").include?("\"#{model_class}\"")
          inject_into_file("app/models/#{parent_model}.rb", "\"#{model_class}\", ", :after => "NESTED_CHILD_MODELS = [")
        end
      end
    end

    if File.exists?("app/models/#{model_url}.rb")
      unless File.read("app/models/#{model_url}.rb").include? "#DON'T REMOVE - NESTED_MODEL_IDENTIFIER#"
        inject_into_file("app/models/#{model_url}.rb", "#DON'T REMOVE - NESTED_MODEL_IDENTIFIER#\n\n\t" , before: "######### DON`T REMOVE - belongs_to ##############")
      end
    end
    #################
  end


  ### COPY GENERAL USED FILES
  def general_files
    shared_dir = ['app', 'views', 'shared'].compact
    copy_file_unless_exists "app/helpers/mobinis_helper.rb",  File.join(['app', 'helpers', "mobinis_helper.rb"].flatten)
    copy_file_unless_exists "app/helpers/ransack_search_helper.rb",  File.join(['app', 'helpers', "ransack_search_helper.rb"].flatten)
    copy_file_unless_exists "app/views/shared/_error_messages.html.erb", File.join([shared_dir, "_error_messages.html.erb"].flatten)
    copy_file_unless_exists "app/views/shared/_modal_columns.html.erb",  File.join([shared_dir, "_modal_columns.html.erb"].flatten)
    copy_file_unless_exists "app/models/import.rb",  File.join(['app', 'models', "import.rb"].flatten)
    copy_file_unless_exists "app/controllers/import_controller.rb",  File.join(['app', 'controllers', "import_controller.rb"].flatten)
    copy_file_unless_exists "app/controllers/mobini_scaffold_controller.rb",  File.join(['app', 'controllers', "mobini_scaffold_controller.rb"].flatten)
    sub_file("/app/controllers/application_controller.rb", "class ApplicationController < ActionController::Base", "class ApplicationController < MobiniScaffoldController  #ActionController::Base in MobiniScaffoldController", behavior) if replace_shared?
  end
end
