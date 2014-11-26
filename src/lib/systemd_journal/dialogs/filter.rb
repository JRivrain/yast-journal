require 'yast'
require 'systemd_journal/dialogs/helpers'

Yast.import "UI"
Yast.import "Label"

module SystemdJournal
  module Dialogs
    # Dialog allowing the user to set the filter used to display the journal
    # entries in SystemdJournal::ViewLogDialog
    class Filter

      include Yast::UIShortcuts
      include Yast::I18n
      include Helpers

      INPUT_WIDTH = 20

      def initialize(filter)
        textdomain "systemd_journal"

        @filter = filter
      end

      # Displays the dialog and returns user's selection of filter options.
      #
      # @return [Hash] filter options or empty Hash if user cancelled
      def run
        return nil unless create_dialog

        begin
          case Yast::UI.UserInput.to_sym
          when :cancel
            {}
          when :ok
            widgets_values
          else
            raise "Unexpected input #{input}"
          end
        ensure
            Yast::UI.CloseDialog
        end
      end

    private

      # Translates the value of the widgets to the structure used in the filter
      # 
      # @returns [Hash] Hash containing :time, :source and other keys only when
      #                 they are relevant
      def widgets_values
        values = {
          time: Yast::UI.QueryWidget(Id(:time), :CurrentButton),
          source: Yast::UI.QueryWidget(Id(:source), :CurrentButton)
        }
        if values[:time] == :dates
          values[:since] = time_from_widgets_for(:since)
          values[:until] = time_from_widgets_for(:until)
        end
        case values[:source]
        when :unit
          values[:unit] = Yast::UI.QueryWidget(Id(:unit_field), :Value)
        when :file
          values[:file] = Yast::UI.QueryWidget(Id(:file_field), :Value)
        end
        values
      end

      # Draws the dialog
      def create_dialog
        Yast::UI.OpenDialog(
          VBox(
            # Header
            Heading(_("Journal filter")),
            # Time options
            Frame(
              _("When"),
              RadioButtonGroup(
                Id(:time),
                VBox(*time_buttons)
              )
            ),
            VSpacing(0.3),
            # Source options
            Frame(
              _("Generated by"),
              RadioButtonGroup(
                Id(:source),
                VBox(*source_buttons)
              )
            ),
            VSpacing(0.3),
            # Footer buttons
            HBox(
              PushButton(Id(:cancel), Yast::Label.CancelButton),
              PushButton(Id(:ok), Yast::Label.OKButton)
            )
          )
        )
      end

      # Array of radio buttons to select the time frame
      def time_buttons
        options = [
          [:current_boot, _("Since system's boot")],
          [:previous_boot, _("On previous boot")],
          [:dates, _("Between these dates"), HSpacing(1), *dates_widgets]
        ]
        radio_buttons_for(options, value: @filter[:time])
      end

      # Array of radio buttons to select the source
      def source_buttons
        options = [
          [:all, _("Any source")],     
          [:unit, _("This systemd unit"), HSpacing(1), unit_widget],
          [:file, _("This file (executable or device)"), HSpacing(1), file_widget]
        ]
        radio_buttons_for(options, value: @filter[:source])
      end

      # Array of widgets for selecting date/time thresholds
      def dates_widgets
        [
          *time_widgets_for(:since, @filter[:since]),
          Label("-"),
          *time_widgets_for(:until, @filter[:until])
        ]
      end

      # Widget representing @filter[:unit]
      def unit_widget
        current = @filter.fetch(:unit, "")
        MinWidth(INPUT_WIDTH, InputField(Id(:unit_field), "", current))
      end

      # Widget representing @filter[:file]
      def file_widget
        current = @filter.fetch(:file, "")
        MinWidth(INPUT_WIDTH, InputField(Id(:file_field), "", current))
      end
    end
  end
end
