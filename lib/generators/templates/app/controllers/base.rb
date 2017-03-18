# encoding : utf-8
<% if namespaced? -%>
require_dependency "application_controller"
<% end -%>
class <%= namespace_for_class %><%= model_pluralize %>Controller < ApplicationController
  authorize_resource #Check abilities with CanCan

  <%= 'before_action :verify_admin' if admin_only? -%>
  require "zip"
  before_action :load_<%= singular_table_name %>, only: [:show, :edit, :update, :destroy]

  def import
  end

  # GET <%= route_url %>
  def index
    if current_user.visible_fields.select{|vf| vf.model=="<%=singular_table_name%>"}.size == 0
      ((<%= model_class %>.attributes_allowed_in_index - ["id","created_at","updated_at"])[0..6]).each_with_index do |field, index|
        current_user.visible_fields.create(model: "<%=singular_table_name%>", field: "#{field}", position: index+1)
      end
    end

    @params_q = ""
    unless params[:q].blank?
      params[:page] ||= 1
      param = params[:q].to_s.gsub "[","{"
      param.gsub! "]","}"
      @params_q = eval param
      q = @params_q.dup
      <%= model_class %>.attributes_allowed_in_index.select{|a| <%= model_class %>.attr_type(a) == "date"}.each do |att|
        begin
          q["#{att}_gteq"] = @params_q[att+"_gteq"].to_date unless @params_q["#{att}_gteq"].blank?
          begin
            q["#{att}_lteq"] = @params_q[att+"_lteq"].to_date unless @params_q["#{att}_lteq"].blank?
          rescue
            q.delete "#{att}_gteq"
            q.delete "#{att}_lteq"
            flash[:error] = "#{att.titleize}: #{@params_q[att+"_lteq"]} não é uma data válida"
          end
        rescue
          q.delete "#{att}_gteq"
          q.delete "#{att}_lteq"
          flash[:error] = "#{att.titleize}: #{@params_q[att+"_gteq"]} não é uma data válida"
        end
      end
      <%= model_class %>.attributes_allowed_in_index.select{|a| <%= model_class %>.attr_type(a) == "datetime"}.each do |att|
        begin
          q["#{att}_gteq"] = (@params_q[att+"_gteq"]).to_datetime unless @params_q["#{att}_gteq"].blank?
          begin
            q["#{att}_lteq"] = (@params_q[att+"_lteq"]).to_datetime unless @params_q["#{att}_lteq"].blank?
          rescue
            q.delete "#{att}_gteq"
            q.delete "#{att}_lteq"
            flash[:error] = "#{att.titleize}: #{@params_q[att+"_lteq"]} não é uma data válida"
          end
        rescue
          q.delete "#{att}_gteq"
          q.delete "#{att}_lteq"
          flash[:error] = "#{att.titleize}: #{@params_q[att+"_gteq"]} não é uma data válida"
        end
      end
    else
      params[:page] ||= (session[:paginate]["<%= singular_table_name %>"] unless session[:paginate].blank? or session[:paginate]["<%= singular_table_name %>"].blank?) || 1
      q = {}
    end
    params[:q] = q unless q.blank?
    do_sort_and_paginate("<%= singular_table_name %>")

    @search = <%= model_class %>.search(params[:q])

    @<%= plural_table_name %>_scope = @search.result().sorting(params[:sorting])
    @<%= plural_table_name %> = @<%= plural_table_name %>_scope.paginate(
        page: params[:page] || 1,
        per_page: 15
      ).to_a

    respond_to do |format|
      format.html{
        render
      }
      format.csv{ export_csv if <%= model_class %>::EXPORT}
      format.pdf{
        if <%= model_class %>::EXPORT
          pdfcontent = PdfReport.new.to_pdf(<%= model_class %>,@<%= plural_table_name %>)
          send_data pdfcontent
        end
      }
      # format.json{
      #   postcode = params['postcode']

      #   @<%= singular_table_name %> = <%= model_class%>.order(:name).where("name like ?", "%#{postcode}%") if postcode

      #   render json: @<%= singular_table_name %>.map(&:name) if @<%=singular_table_name%>
      # }      
    end
  end

  # GET <%= route_url %>/1
  def show
  end

  # GET <%= route_url %>/new
  def new
    @<%= singular_table_name %> = <%= model_class %>.new
  end

  # GET <%= route_url %>/1/edit
  def edit
  end

  # POST <%= route_url %>
  def create
    @<%= singular_table_name %> = <%= model_class %>.new(<%=singular_table_name%>_params)

    if @<%= singular_table_name %>.save
      current_user.add_role :show, @<%= singular_table_name %> if @user_ability.can?(:show_own_registers, nil)
      current_user.add_role :update, @<%= singular_table_name %> if @user_ability.can?(:edit_own_registers, nil)
      current_user.add_role :destroy, @<%= singular_table_name %> if @user_ability.can?(:destroy_own_registers, nil)
      Rails.cache.write("user_ability_#{current_user.id}", Ability.new(current_user), expires_in: 1.hour)
      redirect_to @<%= singular_table_name %>, notice: t("views.<%= singular_table_name %>.notice.created", default: t("general.notice.created"))
    else
      render action: 'new'
    end
  end

  # PATCH/PUT <%= route_url %>/1
  def update
    if @<%= singular_table_name%>.update(<%=singular_table_name%>_params)
      redirect_to @<%= singular_table_name %>, notice: t("views.<%= singular_table_name %>.notice.updated", default: t("general.notice.updated"))
    else
      render action: 'edit'
    end
  end

  # DELETE <%= route_url %>/1
  def destroy
    begin
      @<%= singular_table_name%>.destroy
      current_user.remove_role :show, @<%= singular_table_name %>
      current_user.remove_role :update, @<%= singular_table_name %>
      current_user.remove_role :destroy, @<%= singular_table_name %>
      Rails.cache.write("user_ability_#{current_user.id}", Ability.new(current_user), expires_in: 1.hour)
      flash[:notice] = t("views.<%= singular_table_name %>.notice.deleted", default: t("general.notice.deleted"))
    rescue ActiveRecord::DeleteRestrictionError => e
      @<%=singular_table_name%>.errors.add(:base, e)
      flash[:error] = e
    ensure
      redirect_to <%= index_route %>_url
    end
  end

  private
  def load_<%= singular_table_name %>
    @<%= singular_table_name %> = <%= model_class %>.find(params[:id])
  end

  def <%=singular_table_name%>_params
    params.require(:<%= singular_table_name %>).permit(<%= model_class %>.permitted_attributes)
  end

  def export_csv
    require 'csv'
    if <%= model_class %>::NESTED_CHILD_MODELS.size == 0
      csv_modelo_atual = generate_model_csv()
      send_data csv_modelo_atual
    else
       string_io = Zip::OutputStream.write_buffer { |zos|
        zos.put_next_entry(t("<%=singular_table_name%>.menu")+".csv")
        zos.puts generate_model_csv

        <%= model_class %>::NESTED_CHILD_MODELS.each do |child_class|
          zos.put_next_entry(t("#{child_class.underscore.gsub "/", "_"}.menu")+".csv")
          zos.puts generate_nested_csv(child_class)
        end
      }
      #rewind the buffer
      string_io.rewind
      #Transform the string_io in a binary buffer
      binary_zip = string_io.sysread
      #send zip file to user
      send_data binary_zip, filename: t("<%=singular_table_name%>.menu")+" - export in csv.zip", type: 'application/zip'
    end
  end

  def generate_model_csv
    CSV.generate do |csv|
        csv << <%= model_class %>.attributes_allowed_in_index
        @<%= plural_table_name %>.to_a.each{ |o|
          csv << <%= model_class %>.attributes_allowed_in_index.map{ |a| o[a] }
        }
      end
  end

  def generate_nested_csv(nested_child)
    child_class = nested_child.constantize
    child_name = nested_child.tableize.gsub "/", "_"
    CSV.generate do |csv|
        csv << [t("<%=singular_table_name%>.menu")]+child_class.attributes_allowed_in_index
        @<%= plural_table_name %>.to_a.each { |parent|
          child_class.where(<%= singular_table_name %>_id: parent.id).each { |o|
            csv << [parent.caption_tag]+child_class.attributes_allowed_in_index.map{ |a| o[a] }
          }
        }
      end
  end

  def verify_admin
    authorize! :admin, nil
  end
end
