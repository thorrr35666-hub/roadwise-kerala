import * as ImagePicker from 'expo-image-picker';
import * as Location from 'expo-location';
import { supabase } from './supabase';

export async function pickReportPhoto(): Promise<ImagePicker.ImagePickerAsset|null> {
  const permission=await ImagePicker.requestMediaLibraryPermissionsAsync();
  if(!permission.granted) throw new Error('Photo library permission was not granted.');
  const result=await ImagePicker.launchImageLibraryAsync({mediaTypes:['images'],quality:0.75,allowsEditing:true});
  return result.canceled ? null : result.assets[0];
}
export async function captureReportLocation(): Promise<{latitude:number;longitude:number}> {
  const permission=await Location.requestForegroundPermissionsAsync();
  if(!permission.granted) throw new Error('Location permission was not granted.');
  const position=await Location.getCurrentPositionAsync({accuracy:Location.Accuracy.Balanced});
  return {latitude:position.coords.latitude,longitude:position.coords.longitude};
}
export async function submitReport(input:{
  title:string;defect_type:string;severity:string;location_text:string;description:string;
  latitude:number|null;longitude:number|null;photo:ImagePicker.ImagePickerAsset|null;
}) {
  if(!supabase) throw new Error('Connect Supabase first by setting the EXPO_PUBLIC variables in .env.');
  const {data:{user}}=await supabase.auth.getUser();
  if(!user) throw new Error('Sign in before submitting a report.');
  let photo_path:string|null=null;
  if(input.photo) {
    const response=await fetch(input.photo.uri);
    const blob=await response.blob();
    const ext=(input.photo.fileName?.split('.').pop()||'jpg').replace(/[^a-zA-Z0-9]/g,'');
    photo_path=`${user.id}/${Date.now()}.${ext}`;
    const {error:uploadError}=await supabase.storage.from('road-report-photos').upload(photo_path,blob,{contentType:input.photo.mimeType||'image/jpeg',upsert:false});
    if(uploadError) throw uploadError;
  }
  const {data,error}=await supabase.from('road_reports').insert({
    reporter_id:user.id,title:input.title,defect_type:input.defect_type,severity:input.severity,
    location_text:input.location_text,description:input.description||null,
    latitude:input.latitude,longitude:input.longitude,photo_path
  }).select().single();
  if(error) throw error;
  return data;
}
