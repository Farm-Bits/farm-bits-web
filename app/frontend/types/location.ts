export type Segment = {
  id: number;
  name: string;
  site_id: number;
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

export type SiteUser = {
  id: number;
  user_id: number;
  site_id: number;
  role: 'admin' | 'manager' | 'viewer';
  user_name: string;
};
