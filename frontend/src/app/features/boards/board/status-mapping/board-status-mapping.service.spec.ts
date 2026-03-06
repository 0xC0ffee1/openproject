import { TestBed } from '@angular/core/testing';
import {
  of,
  throwError,
} from 'rxjs';
import { BoardStatusMappingService } from './board-status-mapping.service';
import { BoardActionsRegistryService } from 'core-app/features/boards/board/board-actions/board-actions-registry.service';
import { BoardService } from 'core-app/features/boards/board/board.service';
import { ReactBridge } from 'core-react/bridge/react-bridge';
import { Board } from 'core-app/features/boards/board/board';
import { GridWidgetResource } from 'core-app/features/hal/resources/grid-widget-resource';
import { BoardActionService } from 'core-app/features/boards/board/board-actions/board-action.service';
import { I18nService } from 'core-app/core/i18n/i18n.service';
import { HalResourceNotificationService } from 'core-app/features/hal/services/hal-resource-notification.service';

describe('BoardStatusMappingService', () => {
  let service:BoardStatusMappingService;
  let boardActionRegistry:jasmine.SpyObj<BoardActionsRegistryService>;
  let boardService:jasmine.SpyObj<BoardService>;
  let i18n:jasmine.SpyObj<I18nService>;
  let halNotification:jasmine.SpyObj<HalResourceNotificationService>;

  const fakeStatuses = [
    { id: '1', name: 'New', href: '/api/v3/statuses/1', color: { hexColor: '#999' } },
    { id: '2', name: 'In Progress', href: '/api/v3/statuses/2', color: { hexColor: '#0a0' } },
    { id: '3', name: 'Done', href: '/api/v3/statuses/3', color: { hexColor: '#00f' } },
  ];

  let fakeActionService:{ loadAvailable:jasmine.Spy; filterName:string };
  let fakeWidget:{ options:{ queryId:string; filters:unknown[] } };
  let fakeBoard:Board;

  const flushPromises = async () => {
    await Promise.resolve();
    await Promise.resolve();
  };

  beforeEach(() => {
    fakeActionService = {
      loadAvailable: jasmine.createSpy('loadAvailable').and.returnValue(of(fakeStatuses)),
      filterName: 'status',
    };

    boardActionRegistry = jasmine.createSpyObj<BoardActionsRegistryService>('BoardActionsRegistryService', ['get']);
    boardActionRegistry.get.and.returnValue(fakeActionService as unknown as BoardActionService);

    boardService = jasmine.createSpyObj<BoardService>('BoardService', ['save']);
    i18n = jasmine.createSpyObj<I18nService>('I18nService', ['t']);
    halNotification = jasmine.createSpyObj<HalResourceNotificationService>('HalResourceNotificationService', ['handleRawError']);
    i18n.t.and.callFake((key:string) => {
      if (key === 'js.boards.lists.status_mapping.dialog_title') {
        return 'Configure column';
      }

      if (key === 'js.boards.lists.status_mapping.dialog_subtitle') {
        return 'Select the statuses to include in this column';
      }

      return key;
    });

    fakeWidget = {
      options: {
        queryId: '42',
        filters: [
          { status: { operator: '=', values: ['1'] } },
        ],
      },
    };

    fakeBoard = {} as Board;

    TestBed.configureTestingModule({
      providers: [
        BoardStatusMappingService,
        { provide: BoardActionsRegistryService, useValue: boardActionRegistry },
        { provide: BoardService, useValue: boardService },
        { provide: I18nService, useValue: i18n },
        { provide: HalResourceNotificationService, useValue: halNotification },
      ],
    });

    service = TestBed.inject(BoardStatusMappingService);
  });

  it('calls loadAvailable on the action service', async () => {
    spyOn(ReactBridge, 'openDialog').and.resolveTo(null);
    await service.openDialog(fakeBoard, fakeWidget as unknown as GridWidgetResource, () => { /* noop */ });

    expect(fakeActionService.loadAvailable).toHaveBeenCalledWith(new Set(), '');
  });

  it('reads current filter values from widget options', async () => {
    const openDialogSpy = spyOn(ReactBridge, 'openDialog').and.resolveTo(null);
    await service.openDialog(fakeBoard, fakeWidget as unknown as GridWidgetResource, () => { /* noop */ });
    const props = openDialogSpy.calls.mostRecent().args[1];

    expect(props.currentFilterValues).toEqual(['1']);
    expect(props.title).toEqual('Configure column');
    expect(props.subtitle).toEqual('Select the statuses to include in this column');
    expect(props.placeholder).toEqual('js.boards.lists.status_mapping.filter_placeholder');
    expect(props.noSelectionNotice).toEqual('js.boards.lists.status_mapping.no_selection_notice');
  });

  it('on dialog submit: updates filters and saves board', async () => {
    spyOn(ReactBridge, 'openDialog').and.resolveTo(['1', '2']);
    boardService.save.and.returnValue(of(fakeBoard));
    const onReload = jasmine.createSpy('onReload');

    await service.openDialog(fakeBoard, fakeWidget as unknown as GridWidgetResource, onReload);

    expect(fakeWidget.options.filters).toEqual([
      { status: { operator: '=', values: ['1', '2'] } },
    ]);

    // eslint-disable-next-line @typescript-eslint/unbound-method
    expect(boardService.save).toHaveBeenCalledWith(fakeBoard);
    expect(onReload).toHaveBeenCalledOnceWith();
  });

  it('on save failure: reverts filters and forwards the error', async () => {
    const error = new Error('save failed');
    spyOn(ReactBridge, 'openDialog').and.resolveTo(['1', '2']);
    boardService.save.and.returnValue(throwError(() => error));

    const originalFilters = fakeWidget.options.filters;

    await service.openDialog(fakeBoard, fakeWidget as unknown as GridWidgetResource, () => { /* noop */ });
    await flushPromises();

    expect(fakeWidget.options.filters).toBe(originalFilters);
    // eslint-disable-next-line @typescript-eslint/unbound-method
    expect(halNotification.handleRawError).toHaveBeenCalledWith(error);
  });

  it('on dialog cancel: no save call', async () => {
    spyOn(ReactBridge, 'openDialog').and.resolveTo(null);
    await service.openDialog(fakeBoard, fakeWidget as unknown as GridWidgetResource, () => { /* noop */ });

    // eslint-disable-next-line @typescript-eslint/unbound-method
    expect(boardService.save).not.toHaveBeenCalled();
  });
});
