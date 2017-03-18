class <%= model_class %> < ActiveRecord::Base
  <%- if attributes.any?(&:password_digest?) -%>
    has_secure_password
  <%- end -%>
  resourcify

  IMPORT = <%= have_import? %>
  EXPORT = <%= have_export? %>

  ###### DON'T REMOVE - ATTRIBUTE TYPES ############
  ATTR_TYPE = {"id" => "integer", <%=  attributes.map{ |attr| "\"#{att_name(attr.name)}\" => \"#{attr.type}\""}.join(", ") %>, "created_at" => "datetime", "updated_at" => "datetime"}
  ATTR_CLASS = {<%= attributes.select{|a| a.type == :references}.map{ |attr| "\"#{att_name(attr.name)}_id\" => #{attr_class_for_form(attr.name,attr)}"}.join(", ") %>}

  def self.attr_type(attr_name)
    return ATTR_TYPE[attr_name]
  end
  ##################################################

  ############## VALIDATIONS #######################
  ##################################################

  ###### DON'T REMOVE - NESTED CHILD MODELS ########
  NESTED_CHILD_MODELS = []
  ##################################################

  ######### DON`T REMOVE - belongs_to ##############
  ##################################################

  ######### DON`T REMOVE - has_many ################
  ##################################################

  ########### DON`T REMOVE - nested ################
  ##################################################

  ############# DON`T REMOVE - file ################
<%- attributes.select{|att| att.type == :file || att.type == :image }.each do |attribute| -%>
  has_attached_file :<%= attribute.name %><%- unless attribute.type == :file -%> , :styles => { :small => "150x150>" } <%- end -%>,
      :url  => "/assets/<%=model_url%>/<%= attribute.name %>/:id/:style/:basename.:extension"
    validates_attachment_presence :<%= attribute.name%>
    validates_attachment_size :<%= attribute.name%>, :less_than => 5.megabytes
    validates_attachment_content_type :<%= attribute.name %>, :content_type => <%= attribute.type == :image ? "ApplicationController.helpers.image_types" : "ApplicationController.helpers.file_types" %>
<%- end -%>
  ##################################################

  ######### DON`T REMOVE - price ###################
<%- attributes.select{|att| att.type == :price }.each do |attribute| -%>
  monetize :<%= attribute.name %>_cents
<%- end -%>
  ##################################################

  ######### DON`T REMOVE - ENUMS ###################
  ##################################################

  # You can OVERRIDE this method used in model form and search form (in belongs_to relation)
  def caption_tag
    (self["nome"] || self[:caption] || self["label"] || self["description"] || self["id"])
  end

  def self.permitted_attributes
    return <%= attributes_without_type.map{ |attr| ":#{att_name(attr)}" }.join(", ") %>### DON'T REMOVE - Used to add Attr to Nested models ###
  end  

  def self.attributes_allowed_in_index
    return "id", <%=  attributes.select{|att| att.type != :file && att.type != :image  }.map{ |attr| "\"#{att_name(attr.name)+(attr.type == :references ? '_id' : '')}\"" }.join(", ") %>, "created_at", "updated_at"
  end

  def self.sorted
    #alter this to change the ordenation  or scope ransack field
    all
  end
  ######## DON`T REMOVE - scopes ###################
  scope :sorting, lambda{ |option|
    attribute = option[:attribute] if option
    direction = option[:sorting] if option

    #feel free to change the default values
    attribute ||= "id"
    direction ||= "DESC"

    order("#{attribute} #{direction}")
  }

<%- attributes.select{|att| att.type == :boolean }.each do |attribute| -%>
  scope :<%= attribute.name %>, lambda{where(<%=attribute.name%>: true)}
  scope :not_<%= attribute.name %>, lambda{where(<%=attribute.name%>: false)}
<%- end -%>
  ##################################################
end
