/* Copyright 2011 Yorba Foundation
 *
 * This software is licensed under the GNU LGPL (version 2.1 or later).
 * See the COPYING file in this distribution. 
 */

// This dialog displays a boolean search configuration.
public class SavedSearchDialog {
    
    // Conatins a search row, with a type selector and remove button.
    private class SearchRowContainer {
        public signal void remove(SearchRowContainer this_row);
        
        private Gtk.ComboBox type_combo;
        private Gtk.HBox box;
        private Gtk.Alignment align;
        private Gtk.Button remove_button;
        
        private SearchRow? my_row = null;
        
        public SearchRowContainer(SearchCondition.SearchType starting_type = 0) {
            // Ordering must correspond with SearchCondition.SearchType
            type_combo = new Gtk.ComboBox.text();
            type_combo.append_text(_("Any text"));
            type_combo.append_text(_("Title"));
            type_combo.append_text(_("Tag"));
            type_combo.append_text(_("Event name"));
            type_combo.append_text(_("File name"));
            type_combo.append_text(_("Media type"));
            type_combo.set_active(starting_type); // Sets default.
            type_combo.changed.connect(on_type_changed);
            
            remove_button = new Gtk.Button();
            remove_button.set_label(" - ");
            remove_button.button_press_event.connect(on_removed);
            
            align = new Gtk.Alignment(0,0,0,0);
        
            box = new Gtk.HBox(false, 8);
            box.pack_start(type_combo, false, false, 0);
            box.pack_start(align, false, false, 0);
            box.pack_start(new Gtk.Alignment(0,0,0,0), true, true, 0); // Fill space.
            box.pack_start(remove_button, false, false, 0);
            box.show_all();
            
            set_type(SearchCondition.SearchType.ANY_TEXT);
        }
        
        private void on_type_changed() {
            set_type(get_search_type());
        }
        
        private void set_type(SearchCondition.SearchType type) {
            if (my_row != null)
                align.remove(my_row.get_widget());
            
            switch (type) {
                case SearchCondition.SearchType.ANY_TEXT:
                case SearchCondition.SearchType.EVENT_NAME:
                case SearchCondition.SearchType.FILE_NAME:
                case SearchCondition.SearchType.TAG:
                case SearchCondition.SearchType.TITLE:
                    my_row = new SearchRowText(this);
                    align.add(my_row.get_widget());
                    break;
                    
                case SearchCondition.SearchType.MEDIA_TYPE:
                    my_row = new SearchRowMediaType(this);
                    align.add(my_row.get_widget());
                    break;
                    
                default:
                    assert(false);
                    break;
            }
        }
        
        public SearchCondition.SearchType get_search_type() {
            return (SearchCondition.SearchType) type_combo.get_active();
        }
        
        private bool on_removed(Gdk.EventButton event) {
            remove(this);
            return false;
        }
        
        public void allow_removal(bool allow) {
            remove_button.sensitive = allow;
        }
        
        public Gtk.Widget get_widget() {
            return box;
        }
        
        public SearchCondition get_search_condition() {
            return my_row.get_search_condition();
        }
    }
    
    // Represents a row-type.
    private abstract class SearchRow {
        public abstract Gtk.Widget get_widget();
        public abstract SearchCondition get_search_condition();
    }
    
    private class SearchRowText : SearchRow {
        private Gtk.HBox box;
        private Gtk.ComboBox text_context;
        private Gtk.Entry entry;
        
        private SearchRowContainer parent;
        
        public SearchRowText(SearchRowContainer parent) {
            this.parent = parent;
            
            // Ordering must correspond with SearchConditionText.Context
            text_context = new Gtk.ComboBox.text();
            text_context.append_text(_("contains"));
            text_context.append_text(_("is exactly"));
            text_context.append_text(_("starts with"));
            text_context.append_text(_("ends with"));
            text_context.append_text(_("does not contain"));
            text_context.append_text(_("is not set"));
            text_context.set_active(0);
            
            entry = new Gtk.Entry();
            entry.set_width_chars(25);
            
            box = new Gtk.HBox(false, 8);
            box.pack_start(text_context, false, false, 0);
            box.pack_start(entry, false, false, 0);
            box.show_all();
        }
        
        public override Gtk.Widget get_widget() {
            return box;
        }
        
        public override SearchCondition get_search_condition() {
            SearchCondition.SearchType type = parent.get_search_type();
            string text = entry.get_text();
            SearchConditionText.Context context = (SearchConditionText.Context) text_context.get_active();
            SearchConditionText c = new SearchConditionText(type, text, context);
            return c;
        }
    }
    
    private class SearchRowMediaType : SearchRow {
        private Gtk.HBox box;
        private Gtk.ComboBox media_context;
        private Gtk.ComboBox media_type;
        
        private SearchRowContainer parent;
        
        public SearchRowMediaType(SearchRowContainer parent) {
            this.parent = parent;
            
            // Ordering must correspond with SearchConditionMediaType.Context
            media_context = new Gtk.ComboBox.text();
            media_context.append_text(_("is"));
            media_context.append_text(_("is not"));
            media_context.set_active(0);
            
            // Ordering must correspond with SearchConditionMediaType.MediaType
            media_type = new Gtk.ComboBox.text();
            media_type.append_text(_("any photo"));
            media_type.append_text(_("a raw photo"));
            media_type.append_text(_("a video"));
            media_type.set_active(0);
            
            box = new Gtk.HBox(false, 8);
            box.pack_start(media_context, false, false, 0);
            box.pack_start(media_type, false, false, 0);
            box.show_all();
        }
        
        public override Gtk.Widget get_widget() {
            return box;
        }
        
        public override SearchCondition get_search_condition() {
            SearchCondition.SearchType search_type = parent.get_search_type();
            SearchConditionMediaType.Context context = (SearchConditionMediaType.Context) media_context.get_active();
            SearchConditionMediaType.MediaType type = (SearchConditionMediaType.MediaType) media_type.get_active();
            SearchConditionMediaType c = new SearchConditionMediaType(search_type, context, type);
            return c;
        }
    }
    
    private Gtk.Builder builder;
    private Gtk.Dialog dialog;
    private Gtk.Button add_criteria;
    private Gtk.ComboBox operator;
    private Gtk.VBox row_box;
    private Gtk.Entry search_title;
    private Gee.ArrayList<SearchRowContainer> row_list = new Gee.ArrayList<SearchRowContainer>();
    
    public SavedSearchDialog() {
        builder = AppWindow.create_builder();
        
        dialog = builder.get_object("Search criteria") as Gtk.Dialog;
        dialog.set_parent_window(AppWindow.get_instance().get_parent_window());
        dialog.set_transient_for(AppWindow.get_instance());
        dialog.response.connect(on_response);
        
        add_criteria = builder.get_object("Add search button") as Gtk.Button;
        add_criteria.button_press_event.connect(on_add_criteria);
        
        search_title = builder.get_object("Search title") as Gtk.Entry;

        row_box = builder.get_object("row_box") as Gtk.VBox;
        
        add_text_search();
        row_list.get(0).allow_removal(false);
        
        operator = builder.get_object("Type of search criteria") as Gtk.ComboBox;
        gtk_combo_box_set_as_text(operator);
        operator.append_text(_("any"));
        operator.append_text(_("all"));
        operator.set_active(0);
        
        // Add buttons for new search.
        Gtk.Button ok_button = new Gtk.Button.from_stock(Gtk.Stock.OK);
        ok_button.can_default = true;
        dialog.add_action_widget(ok_button, Gtk.ResponseType.OK);
        dialog.add_action_widget(new Gtk.Button.from_stock(Gtk.Stock.CANCEL), Gtk.ResponseType.CANCEL);
        dialog.set_default_response(Gtk.ResponseType.OK);
        
        dialog.show_all();
    }
    
    public SavedSearchDialog.edit_existing(SavedSearch saved_search) {
        // TODO
    }
    
    // Displays the dialog.
    public void show() {
        dialog.run();
        dialog.destroy();
    }
    
    // Adds a row of search criteria.
    private bool on_add_criteria(Gdk.EventButton event) {
        add_text_search();
        return false;
    }
    
    private void add_text_search() {
        SearchRowContainer text = new SearchRowContainer();
        add_row(text);
    }
    
    // Appends a row of search criteria to the list and table.
    private void add_row(SearchRowContainer row) {
        if (row_list.size == 1)
            row_list.get(0).allow_removal(true);
        row_box.add(row.get_widget());
        row_list.add(row);
        row.remove.connect(on_remove_row);
    }
    
    // Removes a row of search criteria.
    private void on_remove_row(SearchRowContainer row) {
        row.remove.disconnect(on_remove_row);
        row_box.remove(row.get_widget());
        row_list.remove(row);
        if (row_list.size == 1)
            row_list.get(0).allow_removal(false);
    }

    private void on_response(int response_id) {
        if (response_id == Gtk.ResponseType.OK) {
            if (SavedSearchTable.get_instance().exists(search_title.get_text())) {
                AppWindow.error_message(Resources.rename_search_exists_message(search_title.get_text()));
                return;
            }
                
            // Build the condition list from the search rows, and add our new saved search to the table.
            Gee.ArrayList<SearchCondition> conditions = new Gee.ArrayList<SearchCondition>();
            foreach (SearchRowContainer c in row_list) {
                conditions.add(c.get_search_condition());
            }
            
            // Create the object.  It will be added to the DB and SearchTable automatically.
            SearchOperator search_operator = (SearchOperator)operator.get_active();
            SavedSearchTable.get_instance().create(search_title.get_text(), search_operator, conditions);
        }
    }
}
