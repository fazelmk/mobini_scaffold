# encoding : utf-8
class MknemGenerator < Rails::Generators::Base
  #Nested Existing Model
  require 'generators/scaffold_common_methods'
  require 'generators/scaffold_common_helpers'
  include ScaffoldCommonMethods
  include ScaffoldCommonHelpers
  include Rails::Generators::Migration

  # Resources
  # Generator : http://guides.rubyonrails.org/generators.html
  # ActiveAdmin with MetaSearch : https://github.com/gregbell/active_admin/tree/master/lib/active_admin
  # MetaSearch and ransack : https://github.com/ernie/meta_search & http://erniemiller.org/projects/metasearch/#description & http://github.com/ernie/ransack
  # Generator of rails : https://github.com/rails/rails/blob/master/railties/lib/rails/generators/erb/scaffold/scaffold_generator.rb

  #include Rails::Generators::ResourceHelpers

  source_root File.expand_path('../templates', __FILE__)

  argument :parent_model, :type => :string, :desc => "Name of the parent model with namespace (namespace/model)"
  argument :model_with_namespace, :type => :string, :desc => "Name of the child model with namespace (namespace/model)"

  def start_procedure
    @nested = true
    @myattributes = ["#{parent_model}:references"]
  end

  def generate_model
    generate_nested_model_options_helper
    generate_belongs_and_has_many_helper
    generate_add_attr
  end

  def enum
    enum_helper
  end

  def generate_migration
    @migration_name = "Add#{parent_model.gsub("/","_").camelize}To#{model.classify}"
    generate_migration_helper
  end

  def generate_views
    generate_view_migration_helper
    generate_nested_partials_helper
    generate_associate_nested_views_helper
    generate_add_parent_model_to_inport_view_helper
  end

  def translation
    #translation
    generate_add_parent_to_translation_helper
  end

  def model_namespace
    return (model_with_namespace.split("/").size > 1 ? model_with_namespace.split("/")[0].downcase : nil)
  end

  def model
    model_with_namespace.split("/").size > 1 ? model_with_namespace.split("/")[1] : model_with_namespace
  end
end
