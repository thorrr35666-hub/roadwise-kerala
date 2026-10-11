import { supabase } from './supabase';
import { starterSigns, starterMarkings } from '../data/starter';
import type { Sign, Marking } from '../types';

export async function getSigns(): Promise<Sign[]> {
  if (!supabase) return starterSigns;
  const {data,error}=await supabase.from('signs').select('*').eq('is_published',true).order('name');
  if(error) throw error;
  return (data?.length ? data : starterSigns) as Sign[];
}
export async function getMarkings(): Promise<Marking[]> {
  if (!supabase) return starterMarkings;
  const {data,error}=await supabase.from('markings').select('*').eq('is_published',true).order('name');
  if(error) throw error;
  return (data?.length ? data : starterMarkings) as Marking[];
}
