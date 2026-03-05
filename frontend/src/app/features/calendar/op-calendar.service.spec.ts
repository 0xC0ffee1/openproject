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

import { OpCalendarService } from 'core-app/features/calendar/op-calendar.service';

describe('OP calendar service', () => {
  let service:OpCalendarService;

  beforeEach(() => {
    // This is not a valid constructor call, but since we only want to test a helper method that does not
    // depend on injected services, we can pass null values here.
    // @ts-expect-error ignore invalid constructor call since we don't need a completely valid instance
    service = new OpCalendarService(null, null, null);
  });

  describe('stripYearFromDateFormat', () => {
    it('from dotted syntax', () => {
      expect(service.stripYearFromDateFormat('DD.MM.YYYY')).toEqual('DD.MM.');
    });

    it('from slash syntax', () => {
      expect(service.stripYearFromDateFormat('MM/DD/YYYY')).toEqual('MM/DD');
      expect(service.stripYearFromDateFormat('DD/MM/YYYY')).toEqual('DD/MM');
    });

    it('from dash syntax', () => {
      expect(service.stripYearFromDateFormat('DD-MM-YYYY')).toEqual('DD-MM');
      expect(service.stripYearFromDateFormat('YYYY-MM-DD')).toEqual('MM-DD');
    });

    it('from spaced syntax', () => {
      expect(service.stripYearFromDateFormat('DD MMM YYYY')).toEqual('DD MMM');
      expect(service.stripYearFromDateFormat('DD MMMM YYYY')).toEqual('DD MMMM');
    });

    it('from comma syntax', () => {
      expect(service.stripYearFromDateFormat('MMM DD, YYYY')).toEqual('MMM DD');
      expect(service.stripYearFromDateFormat('MMMM DD, YYY')).toEqual('MMMM DD');
    });
  });
});
