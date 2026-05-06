export type Segment = {
  id: number;
  name: string;
  position: number;
};

export type Site = {
  id: number;
  name: string | null;
  country: string | null;
  city: string | null;
  latitude: string | number | null;
  longitude: string | number | null;
  time_zone: string;
};
