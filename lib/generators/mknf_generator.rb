# encoding : utf-8
class MknfGenerator < Rails::Generators::Base
  #Nested Form
  require 'generators/template_common_methods'
  require 'generators/template_common_helpers'
  include TemplateCommonMethods
  include TemplateCommonHelpers
  include Rails::Generators::Migration

  # Resources
  # Generator : http://guides.rubyonrails.org/generators.html
  # ActiveAdmin with MetaSearch : https://github.com/gregbell/active_admin/tree/master/lib/active_admin
  # MetaSearch and ransack : https://github.com/ernie/meta_search & http://erniemiller.org/projects/metasearch/#description & http://github.com/ernie/ransack
  # Generator of rails : https://github.com/rails/rails/blob/master/railties/lib/rails/generators/erb/scaffold/scaffold_generator.rb

  #include Rails::Generators::ResourceHelpers

  source_root File.expand_path('../templates', __FILE__)

  argument :model, :type => :string, :desc => "Name of the new model Capitalized Xxxxx"
  argument :parent_model, :type => :string, :desc => "Name of the parent model"
  argument :myattributes, :type => :array, :default => [], :banner => "'field:type{option}' 'field:type{option}'"

  class_option :namespace, :default => nil
  class_option :replace_shared, :default => nil
  class_option :without_locales, :default => nil

  def start_procedure
    @nested = true
    myattributes << "#{parent_model}:references"
    @myattributes = myattributes
    general_files
  end

  def generate_model
    generate_model_helper
    generate_belongs_and_has_many_helper
    generate_nested_model_options_helper
  end

  def enum
    enum_helper
  end

  def generate_helper
    dirs = ['app', 'helpers', namespace_alone].compact
    template "app/helpers/model_helper.rb", File.join([dirs, "#{model_table_wthout_namespace}_helper.rb"].flatten)
  end

  def generate_translation
    generate_translation_helper
  end

  def generate_migration
    generate_table_helper
  end

  def add_nested_form
    sub_file("Gemfile", "#gem 'nested_form'", "gem 'nested_form'", behavior)
    Bundler.with_clean_env do
      run "bundle install"
    end
  end

  def generate_views
    generate_nested_partials_helper
    generate_nested_views_helper
    generate_associate_nested_views_helper
  end
end
