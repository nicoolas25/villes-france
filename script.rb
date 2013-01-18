# encoding: utf-8

# Ce script importe les données de l'INSEE concernant les villes de France
# dans une base de donnée postgresql.

# Source des données
# http://www.insee.fr/fr/methodes/nomenclatures/cog/telechargement.asp
#
# Documentation et nomenclature
# http://www.insee.fr/fr/methodes/nomenclatures/cog/documentation.asp
# http://www.insee.fr/fr/methodes/default.asp?page=nomenclatures/cog/doc_variables.htm

require 'csv'
require 'sequel'

# Utilisez vos informations de connexion à la base de données
DB = Sequel.connect(adapter: 'postgres', host: 'localhost', database: 'TODO', user: 'TODO', password: 'TODO')

FILES = { comsimp: 'comsimp2012.utf8.csv',
          arrond:  'arrond2012.utf8.csv',
          canton:  'canton2012.utf8.csv',
          depts:   'depts2012.utf8.csv',
          reg:     'reg2012.utf8.csv',
          missing: 'data.csv'}

def source_path(sym, subdir='insee')
  filename = FILES[sym]
  File.join('sources', subdir.to_s, filename)
end

def import_data_from(options={}, &block)
  csv_options = {headers: true, return_headers: false, header_converters: :symbol}
  path = options[:path] or raise 'Missing option: path'
  table_name = options[:table_name] or raise 'Missing option: table_name'
  STDOUT.puts "Importing #{path}..."
  count = 1
  CSV.foreach(path, csv_options) do |row|
    begin
      attributes = row.to_hash
      block.call(attributes) if block
      DB[table_name].insert(attributes)
      count += 1
    rescue
      STDERR.puts "Error in file #{path}:#{count}"
      STDERR.puts row.inspect
      STDERR.puts attributes.inspect
      raise $!
    end
  end
end

# Import des régions
DB.create_table!(:regions) do
  String :region, size: 2, primary_key: true
  String :cheflieu, size: 5, null: false, unique: true
  String :tncc, size: 1, null: false
  String :ncc, size: 70, null: false, unique: true
  String :nccenr, size: 70, null: false
end
import_data_from(path: source_path(:reg), table_name: :regions)

# Import des départements
DB.create_table!(:departements) do
  String :region, size: 2, null: false
  String :dep, size: 3, primary_key: true
  String :cheflieu, size: 5, null: false, unique: true
  String :tncc, size: 1, null: false
  String :ncc, size: 70, null: false, unique: true
  String :nccenr, size: 70, null: false
end
import_data_from(path: source_path(:depts), table_name: :departements)

# Import des arrondissements
DB.create_table!(:arrondissements) do
  String :region, size: 2, null: false
  String :dep, size: 3, null: false
  String :ar, size: 1, null: false
  String :cheflieu, size: 5, null: false
  String :tncc, size: 1, null: false
  String :artmaj, size: 5, null: true
  String :ncc, size: 70, null: false
  String :artmin, size: 5, null: true
  String :nccenr, size: 70, null: false
  primary_key [:region, :dep, :ar]
end
import_data_from(path: source_path(:arrond), table_name: :arrondissements)

# Import des cantons
DB.create_table!(:cantons) do
  String :region, size: 2, null: false
  String :dep, size: 3, null: false
  String :ar, size: 1, null: true
  String :canton, size: 2, null: false
  String :typct, size: 1, null: false
  String :cheflieu, size: 5, null: false
  String :tncc, size: 1, null: false
  String :artmaj, size: 5, null: true
  String :ncc, size: 70, null: false
  String :artmin, size: 5, null: true
  String :nccenr, size: 70, null: false
  primary_key [:region, :dep, :canton]
end
import_data_from(path: source_path(:canton), table_name: :cantons)

# Import des communes
DB.create_table!(:communes) do
  String :cdc, size: 1, null: false
  String :cheflieu, size: 1, null: false
  String :reg, size: 2, null: false
  String :dep, size: 3, null: false
  String :com, size: 3, null: false
  String :ar, size: 1, null: true
  String :ct, size: 2, null: false
  String :tncc, size: 1, null: false
  String :artmaj, size: 5, null: true
  String :ncc, size: 70, null: false
  String :artmin, size: 5, null: true
  String :nccenr, size: 70, null: false
  unique [:reg, :dep, :com]

  # Extra fields
  String :ci, size: 5, primary_key: true
  String :cp, size: 5, null: false
  Float :latitude
  Float :longitude
end

# Chargement des codes postaux et des coordonées depuis un fichier CSV
$missing_data  = {}
import_options = {headers: true, return_headers: false, header_converters: :symbol}
CSV.foreach(source_path(:missing, '.'), import_options) do |row|
  $missing_data[row[:ci]] = row
end

# Import des données dans la base
import_data_from(path: source_path(:comsimp), table_name: :communes) do |attributes|
  ci                     = "#{attributes[:dep]}#{attributes[:com]}"
  attributes[:ci]        = ci
  attributes[:cp]        = $missing_data[ci][:cp]
  attributes[:longitude] = $missing_data[ci][:longitude].to_f
  attributes[:latitude]  = $missing_data[ci][:latitude].to_f
end

# SQL to run to get the geography position.
DB.run "alter table communes add column position geography(Point,4326);"
DB.run "update communes set position = ST_GeogFromText('SRID=4326;POINT(' || longitude || ' ' || latitude || ')') where latitude is not null;"
