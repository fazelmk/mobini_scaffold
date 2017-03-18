class Import < ActiveRecord::Base
  def self.class_path_generator(model)
    "#{model.split("::").join("_").tableize}_path"
  end

  def self.imports(file,model_str)
    model = model_str.constantize
    return unless model::IMPORT
    spreadsheet = open_spreadsheet(file)
    header = spreadsheet.row(1)
    (2..spreadsheet.last_row).each do |i|
      row = Hash[[header, spreadsheet.row(i)].transpose]
      row.symbolize_keys!
      item = model.find_by_id(row[:id]) || model.new
      item.attributes = row.slice(*model.column_names.map{|x| x.to_sym})
      item.save(validate: false)
    end
  end

  def self.open_spreadsheet(file)
    case File.extname(file.original_filename)
    when ".csv" then Roo::Csv.new(file.path, csv_options: {encoding: Encoding::UTF_8})
    when ".xls" then Roo::Excel.new(file.path, nil, :ignore)
    #when ".xlsx" then Roo::Excelx.new(file.path, nil, :ignore)
    else raise "Unknown file type: #{file.original_filename}"
    end
  end
end
