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
  ChangeDetectionStrategy,
  Component,
  inject,
  Input,
} from '@angular/core';
import { I18nService } from 'core-app/core/i18n/i18n.service';
import { StatusResource } from 'core-app/features/hal/resources/status-resource';
import { QueryResource } from 'core-app/features/hal/resources/query-resource';
import { Highlighting } from 'core-app/features/work-packages/components/wp-fast-table/builders/highlighting/highlighting.functions';

@Component({
  templateUrl: './status-board-header.html',
  styleUrls: ['./status-board-header.sass'],
  host: { class: 'title-container -small' },
  changeDetection: ChangeDetectionStrategy.OnPush,
  standalone: false,
})
export class StatusBoardHeaderComponent {
  private readonly I18n = inject(I18nService);

  @Input() public resource:StatusResource;

  @Input() public query:QueryResource;

  @Input() public statuses:StatusResource[] = [];

  text = {
    status: this.I18n.t('js.work_packages.properties.status'),
  };

  get title():string {
    return this.query?.name ?? this.resource?.name ?? '';
  }

  statusClass(status:StatusResource):string {
    return status.id ? Highlighting.inlineClass('status', status.id) : '';
  }
}
