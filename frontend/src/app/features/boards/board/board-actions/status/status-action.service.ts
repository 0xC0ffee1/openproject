import { Injectable } from '@angular/core';
import { StatusResource } from 'core-app/features/hal/resources/status-resource';
import { CachedBoardActionService } from 'core-app/features/boards/board/board-actions/cached-board-action.service';
import { StatusBoardHeaderComponent } from 'core-app/features/boards/board/board-actions/status/status-board-header.component';
import { imagePath } from 'core-app/shared/helpers/images/path-helper';
import { map } from 'rxjs/operators';
import { Observable } from 'rxjs';
import { QueryResource } from 'core-app/features/hal/resources/query-resource';
import { HalResource } from 'core-app/features/hal/resources/hal-resource';
import { Highlighting } from 'core-app/features/work-packages/components/wp-fast-table/builders/highlighting/highlighting.functions';

@Injectable()
export class BoardStatusActionService extends CachedBoardActionService {
  filterName = 'status';

  resourceName = 'status';

  text = this.I18n.t('js.boards.board_type.board_type_title.status');

  description = this.I18n.t('js.boards.board_type.action_text_status');

  label = this.I18n.t('js.boards.add_list_modal.labels.status');

  icon = 'icon-workflow';

  image = imagePath('board_creation_modal/status.svg');

  localizedName = this.I18n.t('js.work_packages.properties.status');

  headerComponent() {
    return StatusBoardHeaderComponent;
  }

  override headerComponentInputs(query:QueryResource, resource:HalResource|undefined, resources:HalResource[]):Record<string, unknown> {
    return {
      resource,
      query,
      statuses: resources,
    };
  }

  override actionBarClasses(_query:QueryResource, _resource:HalResource|undefined, resources:HalResource[]):string[] {
    return resources
      .filter((status) => !!status.id)
      .map((status) => Highlighting.backgroundClass(this.filterName, status.id!));
  }

  public warningTextWhenNoOptionsAvailable():Promise<string> {
    return Promise.resolve(this.I18n.t('js.boards.add_list_modal.warning.status'));
  }

  protected loadUncached():Observable<StatusResource[]> {
    return this
      .apiV3Service
      .statuses
      .get()
      .pipe(
        map((collection) => collection.elements),
      );
  }
}
