import { supabase } from './supabase';
export async function signIn(email:string,password:string) {
  if(!supabase) throw new Error('Supabase is not configured.');
  const {error}=await supabase.auth.signInWithPassword({email,password});
  if(error) throw error;
}
export async function signUp(email:string,password:string) {
  if(!supabase) throw new Error('Supabase is not configured.');
  const {error}=await supabase.auth.signUp({email,password});
  if(error) throw error;
}
export async function signOut() {
  if(!supabase) return;
  const {error}=await supabase.auth.signOut();
  if(error) throw error;
}
