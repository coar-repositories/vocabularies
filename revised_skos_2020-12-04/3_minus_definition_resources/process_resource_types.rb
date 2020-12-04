#!/usr/bin/env ruby
require 'csv'
require 'rdf'
require 'rdf/vocab'
require 'rdf/ntriples'
require 'rdf/turtle'

def clean_up_definition_value_strings(in_string)
  in_string.gsub(/\n/,' ').strip
end

graph = RDF::Graph.load('../2_minus_xllabels/resource_types.nt')
triples = graph.statements #necessary to get a persistent set of statements which are otherwise recreated from the graph each time

definition_resources_to_delete = []

triples.each do |triple|
  if triple.predicate.eql?(RDF::URI('http://www.w3.org/2004/02/skos/core#definition')) then
    definition_resources_to_delete << triple.object
    graph.delete(triple)
    definition_source_statement = triples.find{|t| t.subject.eql?(triple.object) && t.predicate.eql?(RDF::URI('http://art.uniroma2.it/ontologies/vocbench#hasLink')) }
    if definition_source_statement == nil then
      definition_source_statement = triples.find{|t| t.subject.eql?(triple.object) && t.predicate.eql?(RDF::URI('http://purl.org/dc/terms/source')) }
    end
    definition_source_value = ''
    if definition_source_statement then
      definition_source_value = " [Source: #{definition_source_statement.object}]"
    end
    definition_value_statements = []
    triples.select{|t| t.subject.eql?(triple.object) && t.predicate.eql?(RDF::URI('http://www.w3.org/1999/02/22-rdf-syntax-ns#value')) }.each do |definition_value_statement|
      processed_definition_value = clean_up_definition_value_strings(definition_value_statement.object.to_s)
      if definition_value_statement.object.language == :en
        processed_definition_value = clean_up_definition_value_strings(definition_value_statement.object.to_s + definition_source_value)
      end
      definition_value_statements << RDF::Statement(triple.subject, RDF::URI('http://www.w3.org/2004/02/skos/core#definition'), RDF::Literal(processed_definition_value,language: definition_value_statement.object.language))
    end
    definition_value_statements.each {|s| graph.insert(s)}
  end
end

definition_resources_to_delete.each do |definition_resource_to_delete|
  graph.statements.select{|s| s.subject.eql?(definition_resource_to_delete)}.each{|s| graph.delete(s)}
end

RDF::NTriples::Writer.open("./resource_types.nt") do |writer|
  writer << graph
end

RDF::Turtle::Writer.open("./resource_types.ttl") do |writer|
  writer << graph
end


