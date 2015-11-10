=begin
--------------------------------------------------------------------------------

Process one URI, fetching the relevant triples from the triple-store, recording
stats, and writing an N3 file.

--------------------------------------------------------------------------------
=end

module Ld4lLinkDataServer
  class UriProcessor
    QUERY_OUTGOING_PROPERTIES = <<-END
    CONSTRUCT {
      ?uri ?p ?o
    }
    WHERE { 
      ?uri ?p ?o . 
    }
    END
    QUERY_INCOMING_PROPERTIES = <<-END
    CONSTRUCT {
      ?s ?p ?uri
    }
    WHERE { 
      ?s ?p ?uri . 
    }
    END
    def initialize(ts, files, report, uri)
      @ts = ts
      @files = files
      @report = report
      @uri = uri
    end

    def uri_is_acceptable
      @uri.start_with?(@files.prefix)
    end

    def build_the_graph
      @graph = RDF::Graph.new
      @graph << QueryRunner.new(QUERY_OUTGOING_PROPERTIES).bind_uri('uri', @uri).construct(@ts)
      @graph << QueryRunner.new(QUERY_INCOMING_PROPERTIES).bind_uri('uri', @uri).construct(@ts)
    end

    def write_it_out
      if @files.exists?(@uri)
        obj = @files.get(@uri)
      else
        obj = @files.mk(@uri)
      end

      path = File.expand_path('linked_data.ttl', @files.path_for(@uri))
      RDF::Writer.open(path) do |writer|
        writer << @graph
      end
    end

    def run()
      if (uri_is_acceptable)
        build_the_graph
        write_it_out
        @report.wrote_it(@uri, @graph)
      else
        @report.bad_uri(@uri)
      end
    end
  end
end