//-- copyright
// OpenProject is an open source project management software.
// Copyright (C) the OpenProject GmbH
//
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public License version 3.
//
// OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
// Copyright (C) 2006-2013 Jean-Philippe Lang
// Copyright (C) 2010-2013 the ChiliProject Team
//
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public License
// as published by the Free Software Foundation; either version 2
// of the License, or (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with this program; if not, write to the Free Software
// Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
//
// See COPYRIGHT and LICENSE files for more details.
//++

/***************************************
  TASKBOARD
***************************************/

RB.Taskboard = (function ($) {
  return RB.Object.create(RB.Model, {

    initialize(el:any) {
      const self = this; // So we can bind the event handlers to this object

      this.$ = $(el);
      this.el = el;

      // Associate this object with the element for later retrieval
      this.$.data('this', this);

      // Initialize column widths
      this.colWidthUnit = 107;
      this.defaultColWidth = 1;
      this.loadColWidthPreference();
      this.updateColWidths();

      $('#col_width_input')
        .on('keyup', (evt) => {
          if (evt.which === 13) {
            self.updateColWidths();
          }
        });

      this.initializeTasks();
      this.initializeImpediments();

      this.initializeNewButtons();
      this.initializeSortables();

      this.initializeTaskboardMenus();
    },

    initializeNewButtons() {
      this.$.find('#tasks .add_new.clickable').click(this.handleAddNewTaskClick);
      this.$.find('#impediments .add_new.clickable').click(this.handleAddNewImpedimentClick);
    },

    initializeSortables() {
      this.$.find('#impediments .list').sortable({
        placeholder: 'placeholder',
        start: this.dragStart,
        stop: this.dragStop,
        update: this.dragComplete,
        cancel: '.prevent_edit',
      }).sortable('option', 'connectWith', '#impediments .list');
      $('#impediments .list').disableSelection();

      let list:any;
      let augmentList:any;
      const self = this;

      list = this.$.find('#tasks .list');

      augmentList = function () {
        $(list.splice(0, 50)).sortable({
          placeholder: 'placeholder',
          start: self.dragStart,
          stop: self.dragStop,
          update: self.dragComplete,
          cancel: '.prevent_edit',
        }).sortable('option', 'connectWith', '#tasks .list');
        $('#tasks .list').disableSelection();

        if (list.length > 0) {
          /*globals setTimeout*/
          setTimeout(augmentList, 10);
        }
      };
      augmentList();
    },

    initializeTasks() {
      this.$.find('.task').each(function (this:any, index:any) {
        RB.Factory.initialize(RB.Task, this);
      });
    },

    initializeImpediments() {
      this.$.find('.impediment').each(function (this:any, index:any) {
        RB.Factory.initialize(RB.Impediment, this);
      });
    },

    initializeTaskboardMenus() {
      const toggleOpen = 'open icon-pulldown-up icon-pulldown';

      $('.backlog .backlog-menu > div.menu-trigger').on('click', function () {
        $(this).toggleClass(toggleOpen);
      });

      $('.backlog .backlog-menu > ul.items li.item').on('click', function () {
        $(this).closest('.backlog-menu').find('div.menu-trigger').toggleClass(toggleOpen);
      });
    },

    dragComplete(e:any, ui:any) {
      // Handler is triggered for source and target. Thus the need to check.
      const isDropTarget = (ui.sender === null);

      if (isDropTarget) {
        ui.item.data('this').saveDragResult();
      }
    },

    dragStart(e:any, ui:any) {
      ui.item.addClass('dragging');
    },

    dragStop(e:any, ui:any) {
      ui.item.removeClass('dragging');
    },

    handleAddNewImpedimentClick(e:any) {
      const row = $(this).parents('tr').first();
      $('#taskboard').data('this').newImpediment(row);
    },

    handleAddNewTaskClick(e:any) {
      const row = $(this).parents('tr').first();
      $('#taskboard').data('this').newTask(row);
    },

    loadColWidthPreference() {
      let w = RB.UserPreferences.get('taskboardColWidth');
      if (w === null || w === undefined) {
        w = this.defaultColWidth;
        RB.UserPreferences.set('taskboardColWidth', w);
      }
      $('#col_width input').val(w);
    },

    newImpediment(row:any) {
      let impediment;
      let o;

      impediment = $('#impediment_template').children().first().clone();
      row.find('.list').first().prepend(impediment);

      o = RB.Factory.initialize(RB.Impediment, impediment);
      o.edit();
    },

    newTask(row:any) {
      let task;
      let o;

      task = $('#task_template').children().first().clone();
      row.find('.list').first().prepend(task);

      o = RB.Factory.initialize(RB.Task, task);
      o.edit();
    },

    updateColWidths() {
      // @ts-expect-error TS(2345): Argument of type 'string | number | string[] | und... Remove this comment to see the full error message
      let w = parseInt($('#col_width_input').val(), 10);

      if (isNaN(w) || w <= 0) {
        w = this.defaultColWidth;
      }
      $('#col_width_input').val(w);
      RB.UserPreferences.set('taskboardColWidth', w);
      $('.swimlane').width(this.colWidthUnit * w).css('min-width', this.colWidthUnit * w);
    },
  });
}(jQuery));
