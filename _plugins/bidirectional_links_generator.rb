# frozen_string_literal: true
class BidirectionalLinksGenerator < Jekyll::Generator
    def generate(site)
      graph_nodes = []
      graph_edges = []
  
      all_notes = site.documents
      all_pages = site.pages
  
      all_docs = all_notes + all_pages
  
      link_extension = !!site.config["use_html_extension"] ? '.html' : ''
  
      # Convert all Wiki/Roam-style double-bracket link syntax to plain HTML
      # anchor tag elements (<a>) with "internal-link" CSS class
      all_docs.each do |current_note|
        all_docs.each do |note_potentially_linked_to|
          note_title_regexp_pattern = Regexp.escape(
            File.basename(
              note_potentially_linked_to.basename,
              File.extname(note_potentially_linked_to.basename)
            )
          ).gsub('\_', '[ _]').gsub('\-', '[ -]').capitalize
  
          title_from_data = note_potentially_linked_to.data['title']
          if title_from_data
            title_from_data = Regexp.escape(title_from_data)
          end
  
          new_href = "#{site.baseurl}#{note_potentially_linked_to.url}#{link_extension}"
          anchor_tag = "<a class='internal-link' href='#{new_href}'>\\1</a>"
  
          # Replace double-bracketed links with label using note title
          # [[A note about cats|this is a link to the note about cats]]
          current_note.content.gsub!(
            /\[\[#{note_title_regexp_pattern}\|(.+?)(?=\])\]\]/i,
            anchor_tag
          )
  
          # Replace double-bracketed links with label using note filename
          # [[cats|this is a link to the note about cats]]
          current_note.content.gsub!(
            /\[\[#{title_from_data}\|(.+?)(?=\])\]\]/i,
            anchor_tag
          )
  
          # Replace double-bracketed links using note title
          # [[a note about cats]]
          current_note.content.gsub!(
            /\[\[(#{title_from_data})\]\]/i,
            anchor_tag
          )
  
          # Replace double-bracketed links using note filename
          # [[cats]]
          current_note.content.gsub!(
            /\[\[(#{note_title_regexp_pattern})\]\]/i,
            anchor_tag
          )
        end
  
        # At this point, all remaining double-bracket-wrapped words are
        # pointing to non-existing pages, so let's turn them into disabled
        # links by greying them out and changing the cursor
        current_note.content = current_note.content.gsub(
          /\[\[([^\]]+)\]\]/i, # match on the remaining double-bracket links
          <<~HTML.delete("\n") # replace with this HTML (\\1 is what was inside the brackets)
            <span title='There is no note that matches this link.' class='invalid-link'>
              <span class='invalid-link-brackets'>[[</span>
              \\1
              <span class='invalid-link-brackets'>]]</span></span>
          HTML
        )
      end
  
      # Identify note backlinks and add them to each note
      all_notes.each do |current_note|
        # Nodes: Jekyll
        notes_linking_to_current_note = [] 
        all_notes.filter do |e|
          if e.content.include?(current_note.url)
            backlink = [e.title, e.url, e.excerpt]
            notes_linking_to_current_note.push(backlink)
          end
        end
        current_note.data['backlinks'] = notes_linking_to_current_note
      end
    end
  end