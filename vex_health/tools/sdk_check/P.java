import com.jstyle.blesdkv8.Util.BleSDK;
import com.jstyle.blesdkv8.callback.DataListener2301;
import java.util.*;
public class P {
  static byte[] hex(String s){byte[] b=new byte[s.length()/2];for(int i=0;i<b.length;i++)b[i]=(byte)Integer.parseInt(s.substring(2*i,2*i+2),16);return b;}
  public static void main(String[] a){
    for(String line:a){
      byte[] v=hex(line);
      // BleSDK checks crc? try as-is
      BleSDK.DataParsingWithData(v,new DataListener2301(){
        public void dataCallback(Map<String,Object> m){ System.out.println(line.substring(0,2)+" -> "+new TreeMap<>(m)); }
        public void dataCallback(byte[] b){}
      });
    }
  }
}
