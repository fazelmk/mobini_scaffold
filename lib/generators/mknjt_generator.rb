# encoding : utf-8
class MknjtGenerator < Rails::Generators::Base
  #Nested Join Table
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

  argument :join_model_name, :type => :string, :desc => "Name of the join model"
  argument :model_1, :type => :string, :desc => "Name of the parent model with namespace (namespace/model)"
  argument :model_2, :type => :string, :desc => "Name of the child model with namespace (namespace/model)"
  argument :myattributes, :type => :array, :default => [], :banner => "'field:type{option}' 'field:type{option}'"

  class_option :namespace, :default => nil
  class_option :replace_shared, :default => nil
  class_option :without_locales, :default => nil
  class_option :nested_only_first_model, :default => nil

  def start_procedure
    #behavior é uma variavel que contem o tipo de chamada Invoke (generate), revoke (destroy)
    unless options[:nested_only_first_model].blank?
      myattributes << "#{model_2}:references"
    end

    args = "#{join_model_name} #{model_1} #{myattributes.join(' ')} #{(options[:namespace].blank? ? "" : "--namespace=#{options[:namespace].to_s}")} #{(options[:replace_shared].blank? ? '' : '--replace_shared')} #{(options[:without_locales].blank? ? '' : '--without_locales')}"
    Rails::Generators.invoke 'mknf', args.split(' '), behavior: behavior
    nested_name = join_model_name
    nested_name = options[:namespace].to_s.downcase+"/"+nested_name unless options[:namespace].blank?

    if options[:nested_only_first_model].blank?
      sleep 2
      args = "#{model_2} #{nested_name}"
      Rails::Generators.invoke 'mknp', args.split(' '), behavior: behavior
    end
  end
end
