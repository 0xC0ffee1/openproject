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

import {
  Component, EventEmitter, Input, Output,
} from '@angular/core';
import { firstValueFrom } from 'rxjs';
import { I18nService } from 'core-app/core/i18n/i18n.service';
import { AuthorisationService } from 'core-app/core/model-auth/model-auth.service';
import { OpModalService } from 'core-app/shared/components/modal/modal.service';
import { IsolatedQuerySpace } from 'core-app/features/work-packages/directives/query-space/isolated-query-space';
import { Board } from 'core-app/features/boards/board/board';
import { BoardActionsRegistryService } from 'core-app/features/boards/board/board-actions/board-actions-registry.service';
import { OpContextMenuItem } from 'core-app/shared/components/op-context-menu/op-context-menu.types';
import { BoardService } from 'core-app/features/boards/board/board.service';
import { BoardActionService } from 'core-app/features/boards/board/board-actions/board-action.service';
import { GridWidgetResource } from 'core-app/features/hal/resources/grid-widget-resource';
import { BoardStatusMappingService } from 'core-app/features/boards/board/status-mapping/board-status-mapping.service';
import { WorkPackageInlineCreateService } from 'core-app/features/work-packages/components/wp-inline-create/wp-inline-create.service';
import { BoardListComponent } from 'core-app/features/boards/board/board-list/board-list.component';

@Component({
  selector: 'board-list-menu',
  templateUrl: './board-list-menu.component.html',
  standalone: false,
})
export class BoardListMenuComponent {
  @Input() board:Board;

  @Input() resource:GridWidgetResource;

  @Input() showAddActions = false;

  @Output() onRemove = new EventEmitter<void>();

  @Output() onReload = new EventEmitter<void>();

  constructor(readonly opModalService:OpModalService,
    readonly authorisationService:AuthorisationService,
    private readonly querySpace:IsolatedQuerySpace,
    private readonly boardService:BoardService,
    private readonly boardActionRegistry:BoardActionsRegistryService,
    private readonly statusMappingService:BoardStatusMappingService,
    private readonly wpInlineCreate:WorkPackageInlineCreateService,
    private readonly boardList:BoardListComponent,
    readonly I18n:I18nService) {
  }

  public get menuItems() {
    return async () => {
      const items:OpContextMenuItem[] = [];

      if (this.showAddActions) {
        const [canAdd, canReference] = await Promise.all([
          firstValueFrom(this.wpInlineCreate.canAdd),
          firstValueFrom(this.wpInlineCreate.canReference),
        ]);

        items.push({
          disabled: !canAdd,
          linkText: this.I18n.t('js.card.add_new'),
          onClick: () => {
            this.boardList.addNewCard();
            return true;
          },
        });

        items.push({
          disabled: !canReference,
          linkText: this.I18n.t('js.relation_buttons.add_existing'),
          onClick: () => {
            this.boardList.addReferenceCard();
            return true;
          },
        });
      }

      if (this.board.isAction && this.board.actionAttribute === 'status' && this.canManage) {
        items.push({
          linkText: this.I18n.t('js.boards.lists.configure_statuses'),
          onClick: () => {
            void this.statusMappingService.openDialog(this.board, this.resource, () => {
              this.onReload.emit();
            });
            return true;
          },
        });
      }

      items.push({
        disabled: !this.canDelete,
        linkText: this.I18n.t('js.boards.lists.delete'),
        onClick: () => {
          this.onRemove.emit();
          return true;
        },
      });

      // Add action specific menu entries
      if (this.board.isAction) {
        const additional = await this.actionService.getAdditionalListMenuItems(this.query);
        return items.concat(additional);
      }

      return items;
    };
  }

  public get shouldShowMenu() {
    return this.showAddActions || this.canDelete() || (this.board.isAction && this.canManage);
  }

  private get actionService():BoardActionService {
    return this.boardActionRegistry.get(this.board.actionAttribute!);
  }

  private get canManage() {
    return this.boardService.canManage(this.board);
  }

  public canDelete() {
    return this.canManage && !!this.query.delete;
  }

  private get query() {
    return this.querySpace.query.value!;
  }
}
