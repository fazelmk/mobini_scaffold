require_dependency "application_controller"
class ImportController < ApplicationController
    def index
      if (!(params[:file].blank? || params[:file] == "") && params[:class_name] != "")
        Import.imports(params[:file],params[:class_name])
        class_name = params[:parent_class_name] || params[:class_name]
        redirect_to send Import.class_path_generator(class_name), notice: "Importado com sucesso."
      end
    end
end
