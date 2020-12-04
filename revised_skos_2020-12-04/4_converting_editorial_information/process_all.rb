#!/usr/bin/env ruby
require 'csv'
require 'rdf'
require 'rdf/vocab'
require 'rdf/ntriples'
require 'rdf/turtle'

VOCABS = ['access_rights','resource_types','version_types']
# VOCABS = ['access_rights']
VOCABS_SOURCE_FOLDER_PATH = '../3_minus_definition_resources'

VOCABS.each do |vocab|
  graph = RDF::Graph.load("#{VOCABS_SOURCE_FOLDER_PATH}/#{vocab}.nt")
  triples = graph.statements #necessary to get a persistent set of statements which are otherwise recreated from the graph each time
  triples.select{|t| t.predicate.eql?(RDF::URI('http://art.uniroma2.it/ontologies/vocbench#hasStatus'))}.each do |status_statement|
    new_status_statement = RDF::Statement(status_statement.subject,RDF::URI('http://www.w3.org/2004/02/skos/core#editorialNote'),status_statement.object)
    graph.delete(status_statement)
    graph.insert(new_status_statement)
  end
  
  RDF::NTriples::Writer.open("./#{vocab}.nt") do |writer|
    writer << graph
  end

  RDF::Turtle::Writer.open("./#{vocab}.ttl") do |writer|
    writer << graph
  end
end

