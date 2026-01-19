export type Segment = {
  id: number;
  name: string;
};

export type Site = {
  id: number;
  name: string | null;
  country: string | null;
  city: string | null;
  latitude: string | number | null;
  longitude: string | number | null;
  altitude: string | number | null;
  time_zone: string;
};
