import com.jstyle.blesdkv8.Util.BleSDK;
import com.jstyle.blesdkv8.model.*;
public class T {
  static String h(byte[] b){StringBuilder s=new StringBuilder();for(byte x:b)s.append(String.format("%02x",x));return s.toString();}
  public static void main(String[] a) throws Exception {
    System.out.println("battery "+h(BleSDK.GetDeviceBatteryLevel()));
    System.out.println("version "+h(BleSDK.GetDeviceVersion()));
    System.out.println("mac "+h(BleSDK.GetDeviceMacAddress()));
    System.out.println("gettime "+h(BleSDK.GetDeviceTime()));
    System.out.println("steps0 "+h(BleSDK.GetTotalActivityDataWithMode((byte)0,"")));
    System.out.println("steps2 "+h(BleSDK.GetTotalActivityDataWithMode((byte)2,"")));
    System.out.println("stepsDate "+h(BleSDK.GetTotalActivityDataWithMode((byte)1,"2026-10-22 01:06:05")));
    System.out.println("hr "+h(BleSDK.GetStaticHRWithMode((byte)0,"2026.10.22 13:09:45")));
    System.out.println("sleep "+h(BleSDK.GetDetailSleepDataWithMode((byte)0,"")));
    System.out.println("hrv "+h(BleSDK.GetHRVDataWithMode((byte)2,"")));
    System.out.println("spo2 "+h(BleSDK.Oxygen_data((byte)0,"")));
    System.out.println("temp "+h(BleSDK.GetTemperature_historyData((byte)0,"")));
    System.out.println("dyn "+h(BleSDK.GetDynamicHRWithMode((byte)0,"")));
    System.out.println("meas_hr "+h(BleSDK.SetDeviceMeasurementWithType(AutoTestMode.AutoHeartRate,50,true)));
    System.out.println("meas_spo2_stop "+h(BleSDK.SetDeviceMeasurementWithType(AutoTestMode.AutoSpo2,300,false)));
    System.out.println("meas_hrv "+h(BleSDK.SetDeviceMeasurementWithType(AutoTestMode.AutoHRV,50,true)));
    System.out.println("rt "+h(BleSDK.RealTimeStep(true,true)));
    System.out.println("ppg "+h(BleSDK.setECGRealtimeDuringHRVEnabled(true)));
    System.out.println("find "+h(BleSDK.FindActivityMode()));
    System.out.println("ex "+h(BleSDK.EnterActivityMode(30,5,1)));
    System.out.println("name "+h(BleSDK.SetDeviceName("VEX Band")));
    System.out.println("basic "+h(BleSDK.SetBasic_parameters_of_equipment(true,false)));
    MyAutomaticHRMonitoring m=new MyAutomaticHRMonitoring(); m.setOpen(1); m.setStartHour(8);m.setStartMinute(30);m.setEndHour(22);m.setEndMinute(5);m.setWeek(0x7f);m.setTime(10);
    System.out.println("auto "+h(BleSDK.SetAutomaticHRMonitoring(m, AutoMode.AutoHeartRate)));
    MyPersonalInfo pi=new MyPersonalInfo(); pi.setSex(1);pi.setAge(30);pi.setHeight(175);pi.setWeight(70);pi.setStepLength(70);
    System.out.println("user "+h(BleSDK.SetPersonalInfo(pi)));
  }
}
