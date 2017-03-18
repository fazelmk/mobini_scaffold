# encoding : utf-8
class MkmGenerator < Rails::Generators::Base
  #Migration
  require 'generators/template_common_methods'
  require 'generators/template_common_helpers'
  include TemplateCommonMethods
  include TemplateCommonHelpers
  include Rails::Generators::Migration


  #include Rails::Generators::ResourceHelpers

  source_root File.expand_path('../templates', __FILE__)

  argument :migration_name, :type => :string, :desc => "Name of the migration CamelCase AddXxxToYyy"
  argument :myattributes, :type => :array, :default => [], :banner => "field:type field:type (for bt relation model:references)"
  class_option :namespace, :default => nil

  def variaveis_extras
    @migration_name = migration_name
    @myattributes = myattributes
    if File.exists?("app/models/#{model_url}.rb") && File.read("app/models/#{model_url}.rb").include?("#DON'T REMOVE - NESTED_MODEL_IDENTIFIER#")
      @nested = true
    else
      @nested = false
    end
  end

  def generate_migration
    generate_migration_helper
  end

  def enum
    enum_helper
  end

  def transaltion
    attributes.each do |attribute|
      if attribute.reference?
        inject_into_file("config/locales/pt-BR/model_translation/#{singular_table_name}.yml", "        #{att_name(attribute.name)}_id:\n        #{att_name(attribute.name)}_id_import:\n", :before => "######## DON'T REMOVE - ADD Fields To Translate ###############") if File.exists?("config/locales/pt-BR/model_translation/#{singular_table_name}.yml")
      else
        inject_into_file("config/locales/pt-BR/model_translation/#{singular_table_name}.yml", "        #{attribute.name}:\n        #{attribute.name}_import:\n", :before => "######## DON'T REMOVE - ADD Fields To Translate ###############") if File.exists?("config/locales/pt-BR/model_translation/#{singular_table_name}.yml")
      end
    end
  end

  def add_to_model
    generate_permited_attributes
    generate_belongs_and_has_many_helper
    generate_attachment
    generate_add_attr
  end

  def generate_views
    if @nested == true
      @nested_show = true
    else
      @nested_show = false
    end
    generete_views
  end

  private
  def generete_views
    generate_view_migration_helper
  end

  def model
    return migration_name.scan(/^Add(.*)To(.*)$/).flatten[1].underscore.singularize
  end
end
