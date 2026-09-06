export interface EventDTO {
  id: number;
  title: string;
  description: string;
  date: string; // YYYY-MM-DD
  time: string; // HH:mm
  location: string;
  category: string;
  status: 'Đang diễn ra' | 'Sắp tới' | 'Đã kết thúc' | string;
  color: string;
  icon: string;
}

export interface CreateEventRequest {
  title: string;
  description: string;
  startAt: string; // ISO string YYYY-MM-DDTHH:mm:ss
  endAt: string;   // ISO string YYYY-MM-DDTHH:mm:ss
  location: string;
  category: string;
}
