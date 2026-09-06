export interface NewsDTO {
  id: number;
  title: string;
  content: string;
  imageUrl?: string | null;
  category?: string | null;
  publishedDate?: string | null; // ISO string
}

export interface NewsPayload {
  title: string;
  content: string;
  imageUrl?: string | null;
  category?: string | null;
  isActive?: boolean;
}
