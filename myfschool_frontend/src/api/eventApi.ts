import { axiosClient } from './axiosClient';
import type { EventDTO, CreateEventRequest } from '../types/event';

export const eventApi = {
  getAll: async (): Promise<EventDTO[]> => {
    const response = await axiosClient.get<EventDTO[]>('/events');
    return response.data;
  },

  create: async (data: CreateEventRequest): Promise<any> => {
    const response = await axiosClient.post('/events', data);
    return response.data;
  },
};
