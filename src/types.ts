export type Sign = {
  id: string; name: string; category: 'Regulatory'|'Warning'|'Informatory';
  shape: string; colour: string; meaning: string; typical_location: string;
  standard_reference: string; created_at?: string;
};
export type Marking = {
  id: string; name: string; category: string; appearance: string; meaning: string;
  typical_location: string; common_defects: string; standard_reference: string;
};
export type RoadReport = {
  id: string; title: string; defect_type: string; severity: string; location_text: string;
  description: string|null; latitude: number|null; longitude: number|null;
  photo_path: string|null; status: string; created_at: string;
};
