export const statusLabels:Record<string,string>={orcamento:'Orçamento',aprovado:'Aprovado',agendado:'Agendado',em_andamento:'Em andamento',concluido:'Concluído',cancelado:'Cancelado'};
export const nextStatus:Record<string,string>={orcamento:'aprovado',aprovado:'agendado',agendado:'em_andamento',em_andamento:'concluido'};
export const money=(v:number|string)=>new Intl.NumberFormat('pt-BR',{style:'currency',currency:'BRL'}).format(Number(v));
export const date=(v:string)=>v?new Date(v).toLocaleString('pt-BR',{timeZone:'America/Sao_Paulo',dateStyle:'short',timeStyle:'short'}):'Não agendado';
export type Row=Record<string,any>;
export type Config={url:string,key:string,configured:boolean};
export async function request(c:Config,token:string,path:string,method='GET',body?:unknown){
 const r=await fetch(`${c.url}/rest/v1/${path}`,{method,headers:{apikey:c.key,Authorization:`Bearer ${token}`,'Content-Type':'application/json',Prefer:'return=representation'},...(body!==undefined?{body:JSON.stringify(body)}:{})});
 const raw=await r.text();let data;try{data=raw?JSON.parse(raw):null}catch{throw Error('Resposta inválida do servidor.')}
 if(!r.ok)throw Error(data?.message||'Não foi possível acessar os dados. Entre novamente se a sessão expirou.');return data;
}
export function monthKey(v:string){return new Date(v).toLocaleDateString('en-CA',{timeZone:'America/Sao_Paulo',year:'numeric',month:'2-digit'});}
