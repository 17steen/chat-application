const parseCookie = str => {
  console.log(str);
  if (!str) return {};
  return str
    .split(';')
    .map(vec => vec.split('='))
    .reduce((acc, v) => {
      console.log(acc, v);
      try{
        return acc.set(decodeURIComponent(v[0].trim()),decodeURIComponent([1].trim()))
      }
      catch {
        try{
          acc.set(v[0].trim(),v[1].trim());
        }
        catch{
          console.log("couldn't parse the cookies");
          return acc;
        }
        return acc;
      }
    }, new Map());
}

function getCookieObject() {
  const a = [ ...parseCookie(document.cookie).entries() ];
  console.log(a);
  return a;    
}

function setCookies(key, value){
  let d = new Date();
  d.setTime(d.getTime() + (5 * 60 * 1000)); //expires after 5 minutes for testing purposes
  const expires = "expires="+ d.toUTCString();
  document.cookie = (key + "=" + value + ";" + expires + "; SameSite=Strict; path=/");
}