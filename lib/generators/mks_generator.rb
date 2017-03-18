# encoding : utf-8
class MksGenerator < Rails::Generators::Base
  #Scaffold
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

  argument :model, :type => :string, :desc => "Name of model"
  argument :myattributes, :type => :array, :default => [], :banner => "'field:type{option}' 'field:type{option}'"

  class_option :namespace, :default => nil
  class_option :without_import, :default => nil
  class_option :without_export, :default => nil
  class_option :replace_shared, :default => nil
  class_option :without_locales, :default => nil
  class_option :admin_only, :default => nil

  def start_procedure
    @nested = false
    @myattributes = myattributes
    general_files
  end

  def generate_layout
    inject_into_file("app/views/layouts/_navbar_items.html.erb",
        "\n\t\t\t\t"+'<li><%= link_to t("'+singular_table_name+'.menu"), '+index_route+'_path if @user_ability.can? :index, '+model_class+' %'+'>'+'</li>',
        :after => "<!-- DON`T REMOVE - ADD ITENS IN MENU -->")
  end

  def generate_model
    generate_model_helper
    generate_belongs_and_has_many_helper
  end

  def enum
    enum_helper
  end

  def add_model_to_permissions
    unless admin_only?
      if File.exists?("app/controllers/permissions_controller.rb")
        if File.read("app/controllers/permissions_controller.rb").include?("MODELS_ALLOWS_IN_PERMISSION = []")
          inject_into_file("app/controllers/permissions_controller.rb", "\"#{model_class}\"", :after => "MODELS_ALLOWS_IN_PERMISSION = [")
        else
          unless File.read("app/controllers/permissions_controller.rb").include?("\"#{model_class}\"")
            inject_into_file("app/controllers/permissions_controller.rb", "\"#{model_class}\", ", :after => "MODELS_ALLOWS_IN_PERMISSION = [")
          end
        end
      end
    end
  end

  def generate_translation
    generate_translation_helper
  end

  def generate_migration
    generate_table_helper
  end

  def generate_controller
    dirs = ['app', 'controllers', namespace_alone].compact
    empty_directory File.join(dirs) unless
    template "app/controllers/base.rb", File.join([dirs, "#{model_table_wthout_namespace}_controller.rb"].flatten)
  end

  def generate_helper
    dirs = ['app', 'helpers', namespace_alone].compact
    template   "app/helpers/model_helper.rb", File.join([dirs, "#{model_table_wthout_namespace}_helper.rb"].flatten)
  end

  def generate_views
    namespacedirs = ["app", "views", namespace_alone].compact
    empty_directory File.join(namespacedirs) unless File.directory?(File.join(namespacedirs.flatten))

    dirs = [namespacedirs, model_table_wthout_namespace]
    empty_directory File.join(dirs) unless File.directory?(File.join(dirs.flatten))

    available_views.flatten.each do |view|
      filename = view + ".html.erb"
      view_path = File.join([dirs, filename].flatten)
      template_path   = File.join(["app", "views", filename].flatten)

      template template_path, view_path
    end
  end

  def routes_generate
    routes_in_text = File.read("config/routes.rb")

    if not routes_in_text[/post 'import' => 'import#index'/]
      myroute = "post 'import' => 'import#index'\n"
      myroute += "  match ':model_sym/select_fields' => 'mobini_scaffold#select_fields', :via => [:get, :post]\n"
      route(myroute)
    end

    myroute = "match \"#{plural_table_name}/search_and_filter\" => \"#{plural_table_name}#index\", :via => [:get, :post], :as => :search_#{plural_table_name}\n\t"
    myroute += namespace_alone.blank? ? "" : "namespace :#{namespace_alone} do\n\t\t"
    myroute += "resources :#{model_table_wthout_namespace} do\n" +
      (namespace_alone.blank? ? "\t\t" : "\t\t\t")+"collection do\n"+
        (namespace_alone.blank? ? "\t\t\t" : "\t\t\t\t")+"get :import\n"+
      (namespace_alone.blank? ? "\t\t" : "\t\t\t")+"end\n"+
    (namespace_alone.blank? ? "\t" : "\t\t")+"end\n"
    myroute += "\tend\n" if not namespace_alone.blank?
    route(myroute)
  end
end
