# encoding : utf-8
class MobiniScaffoldController < ActionController::Base
  # Call in AJAX
  def select_fields
    current_user.visible_fields.where(model: "#{params[:model_sym]}").destroy_all
    puts params[:fields]
    params[:fields].each_with_index do |field, index|
      id = current_user.visible_fields.create({ model: "#{params[:model_sym]}", field: "#{field}", position: index+1})
    end
    render :js => "window.location = \'#{root_url+params[:redirect_to]}\'"
  end

  def do_sort_and_paginate(model_sym)
    # Sort
    session[:sorting] ||= {}
    session[:sorting][model_sym] ||= {}
    session[:sorting][model_sym] = params[:sorting] unless params[:sorting].blank?

    # Search and Filter
    session[:search] ||= {}
    session[:search][model_sym] = nil unless params[:nosearch].blank?
    params[:q] ||= session[:search][model_sym]
    session[:search][model_sym] = params[:q]

    # Paginate
    session[:paginate] ||= {}
    session[:paginate][model_sym] ||= nil
    params[:page] ||= session[:paginate][model_sym]
    session[:paginate][model_sym] = params[:page]
  end

  def truncate(value, decimals)
    mult = 10**decimals
    return (value.to_f*mult).floor / mult.to_f
  end
end
