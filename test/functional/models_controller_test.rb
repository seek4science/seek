require 'test_helper'

class ModelsControllerTest < ActionController::TestCase
  
  fixtures :all
  
  include AuthenticatedTestHelper
  include RestTestCases  
  
  def setup
    login_as(:model_owner)
    @object=models(:teusink)
  end
  
  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:models)
  end    
  
  test "show builder with versioned sbml format" do
    m=models(:teusink)
    m.content_blob.dump_data_to_file #required for the form post to work, as it uses the stored file
    get :builder,:id=>m,:version=>2
    assert_response :success
    assert assigns(:model)
    assert_select "div#reactions_panel",:count=>1 #check for one of the boxes - the reactions box
    assert_select "script",:text=>/VmGLT = 97.264/,:count=>1 #check that one of the parameter sets has been recognized from the uploaded file  
  end
  
  test "show builder with sbml format" do
    m=models(:teusink)
    m.content_blob.dump_data_to_file #required for the form post to work, as it uses the stored file
    get :builder,:id=>m
    assert_response :success
    assert assigns(:model)
    assert_select "div#reactions_panel",:count=>1 #check for one of the boxes - the reactions box
    assert_select "script",:text=>/VmGLT = 97.264/,:count=>1 #check that one of the parameter sets has been recognized from the uploaded file  
  end
  
  test "show builder with jws format" do
    m=models(:jws_model)
    m.content_blob.dump_data_to_file #required for the form post to work, as it uses the stored file
    get :builder,:id=>m
    assert_response :success
    assert assigns(:model)
    assert_select "div#reactions_panel",:count=>1 #check for one of the boxes - the reactions box
    assert_select "script",:text=>/VmGLT = 97.264/,:count=>1 #check that one of the parameter sets has been recognized from the uploaded file
  end
  
  test "changing model with jws builder" do
    m=models(:jws_model)
    m.content_blob.dump_data_to_file    
    post :construct,:id=>m,
      "assignmentRules"=>"\r\n",
      "modelname"=>"model1",
      "parameterset"=>"\r\nVmGLT = 99.999\r\nKeqGLT = 1\r\nKmGLTGLCo = 1.1918\r\nKmGLTGLCi = 1.1918\r\nVmGLK = 226.452\r\nKeqGLK = 3800\r\nKmGLKGLCi = 0.08\r\nKmGLKG6P = 30\r\nKmGLKATP = 0.15\r\nKmGLKADP = 0.23\r\nVmPGI = 339.677\r\nKeqPGI = 0.314\r\nKmPGIG6P = 1.4\r\nKmPGIF6P = 0.3\r\nVmPFK = 182.903\r\ngR = 5.12\r\nL0 = 0.66\r\nKmPFKF6P = 0.1\r\nCPFKF6P = 0.0\r\nKmPFKATP = 0.71\r\nCPFKATP = 3\r\nKPFKAMP = 0.0995\r\nCPFKAMP = 0.0845\r\nKiPFKATP = 0.65\r\nCiPFKATP = 100\r\nKPFKF26BP = 0.000682\r\nCPFKF26BP = 0.0174\r\nKPFKF16BP = 0.111\r\nCPFKF16BP = 0.397\r\nVmALD = 322.258\r\nKeqALD = 0.069\r\nKmALDF16P = 0.3\r\nKmALDGAP = 2\r\nKmALDDHAP = 2.4\r\nKmALDGAPi = 10\r\nVmGAPDHf = 1184.52\r\nVmGAPDHr = 6549.68\r\nKmGAPDHGAP = 0.21\r\nKmGAPDHBPG = 0.0098\r\nKmGAPDHNAD = 0.09\r\nKmGAPDHNADH = 0.06\r\nVmG3PDH = 70.15\r\nKeqG3PDH = 4300\r\nKmG3PDHDHAP = 0.4\r\nKmG3PDHNADH = 0.023\r\nKmG3PDHNAD = 0.93\r\nKmG3PDHGLY = 1\r\nVmPGK = 1306.45\r\nKeqPGK = 3200\r\nKmPGKBPG = 0.003\r\nKmPGKP3G = 0.53\r\nKmPGKADP = 0.2\r\nKmPGKATP = 0.3\r\nVmPGM = 2525.81\r\nKeqPGM = 0.19\r\nKmPGMP3G = 1.2\r\nKmPGMP2G = 0.08\r\nVmENO = 365.806\r\nKeqENO = 6.7\r\nKmENOP2G = 0.04\r\nKmENOPEP = 0.5\r\nVmPYK = 1088.71\r\nKeqPYK = 6500\r\nKmPYKPEP = 0.14\r\nKmPYKPYR = 21\r\nKmPYKADP = 0.53\r\nKmPYKATP = 1.5\r\nVmPDC = 174.194\r\nKmPDCPYR = 4.33\r\nnPDC = 1.9\r\nVmADH = 810\r\nKeqADH = \"6.9e-5\"\r\nKmADHACE = 1.11\r\nKmADHETOH = 17\r\nKmADHNADH = 0.11\r\nKmADHNAD = 0.17\r\nKiADHACE = 1.1\r\nKiADHETOH = 90\r\nKiADHNADH = 0.031\r\nKiADHNAD = 0.92\r\nKATPASE = 39.5\r\nKGLYCOGEN = 6\r\nKTREHALOSE = 2.4\r\nKSUCC = 21.4\r\nF26BP = 0.02\r\nSUMAXP = 4.1\r\nKeqAK = 0.45\r\nKeqTPI = 0.045\r\ncompartment = 1\r\nGlyc = 0.0\r\nTrh = 0.0\r\nCO2 = 1\r\nSUCC = 0.0\r\nGLCo = 50\r\nETOH = 50\r\nGLY = 0.15\r\nX = 0.0\r\n\r\n", "events"=>"\r\n", "kinetics"=>"v[vGLK] = (VmGLK*(-(G6P[t]*(SUMAXP-Power[Power[SUMAXP,2]-2*SUMAXP*Prb[t]+8*KeqAK*SUMAXP*Prb[t]+Power[Prb[t],2]-4*KeqAK*Power[Prb[t],2],0.5])/((1-4*KeqAK)*KeqGLK))+GLCi[t]*(-SUMAXP+Prb[t]-4*KeqAK*Prb[t]+Power[Power[SUMAXP,2]-2*SUMAXP*Prb[t]+8*KeqAK*SUMAXP*Prb[t]+Power[Prb[t],2]-4*KeqAK*Power[Prb[t],2],0.5])/(2-8*KeqAK))/(KmGLKATP*KmGLKGLCi*(1+G6P[t]/KmGLKG6P+GLCi[t]/KmGLKGLCi)*(1+(SUMAXP-Power[Power[SUMAXP,2]-2*SUMAXP*Prb[t]+8*KeqAK*SUMAXP*Prb[t]+Power[Prb[t],2]-4*KeqAK*Power[Prb[t],2],0.5])/((1-4*KeqAK)*KmGLKADP)+(-SUMAXP+Prb[t]-4*KeqAK*Prb[t]+Power[Power[SUMAXP,2]-2*SUMAXP*Prb[t]+8*KeqAK*SUMAXP*Prb[t]+Power[Prb[t],2]-4*KeqAK*Power[Prb[t],2],0.5])/((2-8*KeqAK)*KmGLKATP))))\r\nv[vPGI] = VmPGI/KmPGIG6P*(G6P[t]-F6P[t]/KeqPGI)/(1+G6P[t]/KmPGIG6P+F6P[t]/KmPGIF6P)\r\nv[vGLYCO] = KGLYCOGEN\r\nv[vTreha] = KTREHALOSE\r\nv[vPFK] = gR*VmPFK*F6P[t]*(-SUMAXP+Prb[t]-4*KeqAK*Prb[t]+Power[Power[SUMAXP,2]-2*SUMAXP*Prb[t]+8*KeqAK*SUMAXP*Prb[t]+Power[Prb[t],2]-4*KeqAK*Power[Prb[t],2],0.5])*(1+F6P[t]/KmPFKF6P+(-SUMAXP+Prb[t]-4*KeqAK*Prb[t]+Power[Power[SUMAXP,2]-2*SUMAXP*Prb[t]+8*KeqAK*SUMAXP*Prb[t]+Power[Prb[t],2]-4*KeqAK*Power[Prb[t],2],0.5])/((2-8*KeqAK)*KmPFKATP)+gR*F6P[t]*(-SUMAXP+Prb[t]-4*KeqAK*Prb[t]+Power[Power[SUMAXP,2]-2*SUMAXP*Prb[t]+8*KeqAK*SUMAXP*Prb[t]+Power[Prb[t],2]-4*KeqAK*Power[Prb[t],2],0.5])/((2-8*KeqAK)*KmPFKATP*KmPFKF6P))/((2-8*KeqAK)*KmPFKATP*KmPFKF6P*(L0*Power[1+CPFKF26BP*F26BP/KPFKF26BP+CPFKF16BP*F16P[t]/KPFKF16BP,2]*Power[1+2*CPFKAMP*KeqAK*Power[SUMAXP-Power[Power[SUMAXP,2]-2*SUMAXP*Prb[t]+8*KeqAK*SUMAXP*Prb[t]+Power[Prb[t],2]-4*KeqAK*Power[Prb[t],2],0.5],2]/((-1+4*KeqAK)*KPFKAMP*(SUMAXP-Prb[t]+4*KeqAK*Prb[t]-Power[Power[SUMAXP,2]-2*SUMAXP*Prb[t]+8*KeqAK*SUMAXP*Prb[t]+Power[Prb[t],2]-4*KeqAK*Power[Prb[t],2],0.5])),2]*Power[1+CiPFKATP*(-SUMAXP+Prb[t]-4*KeqAK*Prb[t]+Power[Power[SUMAXP,2]-2*SUMAXP*Prb[t]+8*KeqAK*SUMAXP*Prb[t]+Power[Prb[t],2]-4*KeqAK*Power[Prb[t],2],0.5])/((2-8*KeqAK)*KiPFKATP),2]*Power[1+CPFKATP*(-SUMAXP+Prb[t]-4*KeqAK*Prb[t]+Power[Power[SUMAXP,2]-2*SUMAXP*Prb[t]+8*KeqAK*SUMAXP*Prb[t]+Power[Prb[t],2]-4*KeqAK*Power[Prb[t],2],0.5])/((2-8*KeqAK)*KmPFKATP),2]/(Power[1+F26BP/KPFKF26BP+F16P[t]/KPFKF16BP,2]*Power[1+2*KeqAK*Power[SUMAXP-Power[Power[SUMAXP,2]-2*SUMAXP*Prb[t]+8*KeqAK*SUMAXP*Prb[t]+Power[Prb[t],2]-4*KeqAK*Power[Prb[t],2],0.5],2]/((-1+4*KeqAK)*KPFKAMP*(SUMAXP-Prb[t]+4*KeqAK*Prb[t]-Power[Power[SUMAXP,2]-2*SUMAXP*Prb[t]+8*KeqAK*SUMAXP*Prb[t]+Power[Prb[t],2]-4*KeqAK*Power[Prb[t],2],0.5])),2]*Power[1+(-SUMAXP+Prb[t]-4*KeqAK*Prb[t]+Power[Power[SUMAXP,2]-2*SUMAXP*Prb[t]+8*KeqAK*SUMAXP*Prb[t]+Power[Prb[t],2]-4*KeqAK*Power[Prb[t],2],0.5])/((2-8*KeqAK)*KiPFKATP),2])+Power[1+F6P[t]/KmPFKF6P+(-SUMAXP+Prb[t]-4*KeqAK*Prb[t]+Power[Power[SUMAXP,2]-2*SUMAXP*Prb[t]+8*KeqAK*SUMAXP*Prb[t]+Power[Prb[t],2]-4*KeqAK*Power[Prb[t],2],0.5])/((2-8*KeqAK)*KmPFKATP)+gR*F6P[t]*(-SUMAXP+Prb[t]-4*KeqAK*Prb[t]+Power[Power[SUMAXP,2]-2*SUMAXP*Prb[t]+8*KeqAK*SUMAXP*Prb[t]+Power[Prb[t],2]-4*KeqAK*Power[Prb[t],2],0.5])/((2-8*KeqAK)*KmPFKATP*KmPFKF6P),2]))\r\nv[vALD] = VmALD*(F16P[t]-KeqTPI*Power[TRIO[t],2]/(KeqALD*Power[1+KeqTPI,2]))/(KmALDF16P*(1+F16P[t]/KmALDF16P+TRIO[t]/((1+KeqTPI)*KmALDDHAP)+KeqTPI*TRIO[t]/((1+KeqTPI)*KmALDGAP)+KeqTPI*F16P[t]*TRIO[t]/((1+KeqTPI)*KmALDF16P*KmALDGAPi)+KeqTPI*Power[TRIO[t],2]/(Power[1+KeqTPI,2]*KmALDDHAP*KmALDGAP)))\r\nv[vGAPDH] = (-(VmGAPDHr*BPG[t]*NADH[t]/(KmGAPDHBPG*KmGAPDHNADH))+KeqTPI*VmGAPDHf*NAD[t]*TRIO[t]/((1+KeqTPI)*KmGAPDHGAP*KmGAPDHNAD))/((1+NAD[t]/KmGAPDHNAD+NADH[t]/KmGAPDHNADH)*(1+BPG[t]/KmGAPDHBPG+KeqTPI*TRIO[t]/((1+KeqTPI)*KmGAPDHGAP)))\r\nv[vPGK] = VmPGK*(KeqPGK*BPG[t]*(SUMAXP-Power[Power[SUMAXP,2]-2*SUMAXP*Prb[t]+8*KeqAK*SUMAXP*Prb[t]+Power[Prb[t],2]-4*KeqAK*Power[Prb[t],2],0.5])/(1-4*KeqAK)-(-SUMAXP+Prb[t]-4*KeqAK*Prb[t]+Power[Power[SUMAXP,2]-2*SUMAXP*Prb[t]+8*KeqAK*SUMAXP*Prb[t]+Power[Prb[t],2]-4*KeqAK*Power[Prb[t],2],0.5])*P3G[t]/(2-8*KeqAK))/(KmPGKATP*KmPGKP3G*(1+(SUMAXP-Power[Power[SUMAXP,2]-2*SUMAXP*Prb[t]+8*KeqAK*SUMAXP*Prb[t]+Power[Prb[t],2]-4*KeqAK*Power[Prb[t],2],0.5])/((1-4*KeqAK)*KmPGKADP)+(-SUMAXP+Prb[t]-4*KeqAK*Prb[t]+Power[Power[SUMAXP,2]-2*SUMAXP*Prb[t]+8*KeqAK*SUMAXP*Prb[t]+Power[Prb[t],2]-4*KeqAK*Power[Prb[t],2],0.5])/((2-8*KeqAK)*KmPGKATP))*(1+BPG[t]/KmPGKBPG+P3G[t]/KmPGKP3G))\r\nv[vPGM] = VmPGM/KmPGMP3G*(P3G[t]-P2G[t]/KeqPGM)/(1+P3G[t]/KmPGMP3G+P2G[t]/KmPGMP2G)\r\nv[vENO] = VmENO/KmENOP2G*(P2G[t]-PEP[t]/KeqENO)/(1+P2G[t]/KmENOP2G+PEP[t]/KmENOPEP)\r\nv[vPYK] = VmPYK/(KmPYKPEP*KmPYKADP)*(PEP[t]*(SUMAXP-Power[Power[Prb[t],2]-4*KeqAK*Power[Prb[t],2]-2*Prb[t]*SUMAXP+8*KeqAK*Prb[t]*SUMAXP+Power[SUMAXP,2],0.5])/(1-4*KeqAK)-PYR[t]*((Prb[t]-4*KeqAK*Prb[t]-SUMAXP+Power[Power[Prb[t],2]-4*KeqAK*Power[Prb[t],2]-2*Prb[t]*SUMAXP+8*KeqAK*Prb[t]*SUMAXP+Power[SUMAXP,2],0.5])/(2-8*KeqAK))/KeqPYK)/((1+PEP[t]/KmPYKPEP+PYR[t]/KmPYKPYR)*(1+(Prb[t]-4*KeqAK*Prb[t]-SUMAXP+Power[Power[Prb[t],2]-4*KeqAK*Power[Prb[t],2]-2*Prb[t]*SUMAXP+8*KeqAK*Prb[t]*SUMAXP+Power[SUMAXP,2],0.5])/(2-8*KeqAK)/KmPYKATP+(SUMAXP-Power[Power[Prb[t],2]-4*KeqAK*Power[Prb[t],2]-2*Prb[t]*SUMAXP+8*KeqAK*Prb[t]*SUMAXP+Power[SUMAXP,2],0.5])/(1-4*KeqAK)/KmPYKADP))\r\nv[vPDC] = VmPDC*(Power[PYR[t],nPDC]/Power[KmPDCPYR,nPDC])/(1+Power[PYR[t],nPDC]/Power[KmPDCPYR,nPDC])\r\nv[vSUC] = KSUCC*ACE[t]\r\nv[vGLT] = VmGLT*(GLCo-GLCi[t]/KeqGLT)/(KmGLTGLCo*(1+GLCo/KmGLTGLCo+GLCi[t]/KmGLTGLCi+0.91*GLCo*GLCi[t]/(KmGLTGLCi*KmGLTGLCo)))\r\nv[vADH] = -(VmADH/(KiADHNAD*KmADHETOH)*(NAD[t]*ETOH-NADH[t]*ACE[t]/KeqADH)/(1+NAD[t]/KiADHNAD+KmADHNAD*ETOH/(KiADHNAD*KmADHETOH)+KmADHNADH*ACE[t]/(KiADHNADH*KmADHACE)+NADH[t]/KiADHNADH+NAD[t]*ETOH/(KiADHNAD*KmADHETOH)+KmADHNADH*NAD[t]*ACE[t]/(KiADHNAD*KiADHNADH*KmADHACE)+KmADHNAD*ETOH*NADH[t]/(KiADHNAD*KmADHETOH*KiADHNADH)+NADH[t]*ACE[t]/(KiADHNADH*KmADHACE)+NAD[t]*ETOH*ACE[t]/(KiADHNAD*KmADHETOH*KiADHACE)+ETOH*NADH[t]*ACE[t]/(KiADHETOH*KiADHNADH*KmADHACE)))\r\nv[vG3PDH] = VmG3PDH*(-(GLY*NAD[t]/KeqG3PDH)+NADH[t]*TRIO[t]/(1+KeqTPI))/(KmG3PDHDHAP*KmG3PDHNADH*(1+NAD[t]/KmG3PDHNAD+NADH[t]/KmG3PDHNADH)*(1+GLY/KmG3PDHGLY+TRIO[t]/((1+KeqTPI)*KmG3PDHDHAP)))\r\nv[vATP] = KATPASE*((Prb[t]-4*KeqAK*Prb[t]-SUMAXP+Power[Power[Prb[t],2]-4*KeqAK*Power[Prb[t],2]-2*Prb[t]*SUMAXP+8*KeqAK*Prb[t]*SUMAXP+Power[SUMAXP,2],0.5])/(2-8*KeqAK))\r\n\r\n", "functions"=>"\r\n*Power[?] := ?\r\n", "controller"=>"models", "initVal"=>"GLCi[0] = 0.087\r\nPrb[0] = 5\r\nG6P[0] = 1.39\r\nF6P[0] = 0.28\r\nF16P[0] = 0.1\r\nTRIO[0] = 5.17\r\nNAD[0] = 1.2\r\nBPG[0] = 0.0\r\nNADH[0] = 0.39\r\nP3G[0] = 0.1\r\nP2G[0] = 0.1\r\nPEP[0] = 0.1\r\nPYR[0] = 3.36\r\nACE[0] = 0.04\r\n\r\n", 
      "reaction"=>"v[vGLK] {1.0}GLCi + {1.0}Prb = {1.0}G6P\r\nv[vPGI] {1.0}G6P = {1.0}F6P\r\nv[vGLYCO] {1.0}G6P + {1.0}Prb = {1.0}$Glyc\r\nv[vTreha] {2.0}G6P + {1.0}Prb = {1.0}$Trh\r\nv[vPFK] {1.0}F6P + {1.0}Prb = {1.0}F16P\r\nv[vALD] {1.0}F16P = {2.0}TRIO\r\nv[vGAPDH] {1.0}TRIO + {1.0}NAD = {1.0}BPG + {1.0}NADH\r\nv[vPGK] {1.0}BPG = {1.0}P3G + {1.0}Prb\r\nv[vPGM] {1.0}P3G = {1.0}P2G\r\nv[vENO] {1.0}P2G = {1.0}PEP\r\nv[vPYK] {1.0}PEP = {1.0}PYR + {1.0}Prb\r\nv[vPDC] {1.0}PYR = {1.0}$CO2 + {1.0}ACE\r\nv[vSUC] {2.0}ACE + {3.0}NAD = {1.0}$SUCC + {3.0}NADH\r\nv[vGLT] {1.0}$GLCo = {1.0}GLCi\r\nv[vADH] {1.0}ACE + {1.0}NADH = {1.0}NAD + {1.0}$ETOH\r\nv[vG3PDH] {1.0}TRIO + {1.0}NADH = {1.0}NAD + {1.0}$GLY\r\nv[vATP] {1.0}Prb = {1.0}$X\r\n", 
      "steadystateanalysis"=>"on"
    assert_response :success
    assert_select "div#reactions_panel",:count=>1 #check for one of the boxes - the reactions box
    assert_select "script",:text=>/VmGLT = 99.999/,:count=>1 #check that one of the parameter sets has been recognized from the uploaded file
  end    
  
  test "simulate model" do
    m=models(:teusink)
    m.content_blob.dump_data_to_file
    post :simulate,:id=>m,:version=>m.version
    assert_response :success
    assert_select "object[type='application/x-java-applet']",:count=>1
  end
  
  test "shouldn't show hidden items in index" do
    login_as(:aaron)
    get :index, :page => "all"
    assert_response :success
    assert_equal assigns(:models).sort_by(&:id), Authorization.authorize_collection("view", assigns(:models), users(:aaron)).sort_by(&:id), "models haven't been authorized properly"
  end
  
  test "should get new" do
    get :new    
    assert_response :success
  end    
  
  test "should correctly handle bad data url" do
    model={:title=>"Test",:data_url=>"http://sdfsdfkh.com/sdfsd.png"}
    assert_no_difference('Model.count') do
      assert_no_difference('ContentBlob.count') do
        post :create, :model => model, :sharing=>valid_sharing
      end
    end
    assert_not_nil flash.now[:error]
  end
  
  test "should not create invalid model" do
    model={:title=>"Test"}
    assert_no_difference('Model.count') do
      assert_no_difference('ContentBlob.count') do
        post :create, :model => model, :sharing=>valid_sharing
      end
    end
    assert_not_nil flash.now[:error]
  end
  
  test "should create model" do
    assert_difference('Model.count') do
      post :create, :model => valid_model, :sharing=>valid_sharing
    end
    
    assert_redirected_to model_path(assigns(:model))
  end
  
  test "should create model with url" do
    assert_difference('Model.count') do
      assert_difference('ContentBlob.count') do
        post :create, :model => valid_model_with_url, :sharing=>valid_sharing
      end
    end
    assert_redirected_to model_path(assigns(:model))
    assert_equal users(:model_owner),assigns(:model).contributor   
    assert !assigns(:model).content_blob.url.blank?
    assert assigns(:model).content_blob.data.nil?
    assert !assigns(:model).content_blob.file_exists?
    assert_equal "sysmo-db-logo-grad2.png", assigns(:model).original_filename
    assert_equal "image/png", assigns(:model).content_type
  end
  
  test "should create sop and store with url and store flag" do
    model_details=valid_model_with_url
    model_details[:local_copy]="1"
    assert_difference('Model.count') do
      assert_difference('ContentBlob.count') do
        post :create, :model => model_details, :sharing=>valid_sharing
      end
    end
    assert_redirected_to model_path(assigns(:model))
    assert_equal users(:model_owner),assigns(:model).contributor
    assert !assigns(:model).content_blob.url.blank?
    assert !assigns(:model).content_blob.data.nil?
    assert assigns(:model).content_blob.file_exists?
    assert_equal "sysmo-db-logo-grad2.png", assigns(:model).original_filename
    assert_equal "image/png", assigns(:model).content_type
  end  
  
  test "should create with preferred environment" do
    assert_difference('Model.count') do
      model=valid_model
      model[:recommended_environment_id]=recommended_model_environments(:jws).id
      post :create, :model => model, :sharing=>valid_sharing
    end
    
    m=assigns(:model)
    assert m
    assert_equal "JWS Online",m.recommended_environment.title
  end
  
  test "should show model" do
    m = models(:teusink)
    m.save
    get :show, :id => m
    assert_response :success
  end
  
  test "should show model with format and type" do
    m = models(:model_with_format_and_type)
    m.save
    get :show, :id => m
    assert_response :success
  end
  
  test "should get edit" do
    get :edit, :id => models(:teusink).id
    assert_response :success
  end
  
  test "should update model" do
    put :update, :id => models(:teusink).id, :model => { }
    assert_redirected_to model_path(assigns(:model))
  end
  
  test "should update model with model type and format" do
    type=model_types(:ODE)
    format=model_formats(:SBML)
    put :update, :id => models(:teusink).id, :model => {:model_type_id=>type.id,:model_format_id=>format.id }
    assert assigns(:model)
    assert_equal type,assigns(:model).model_type
    assert_equal format,assigns(:model).model_format
  end
  
  test "should destroy model" do
    assert_difference('Model.count', -1) do
      assert_no_difference("ContentBlob.count") do
        delete :destroy, :id => models(:teusink).id
      end
    end
    
    assert_redirected_to models_path
  end
  
  test "should add model type" do
    login_as(:quentin)
    assert_difference('ModelType.count',1) do
      post :create_model_metadata, :attribute=>"model_type",:model_type=>"fred"
    end
    
    assert_response :success
    assert_not_nil ModelType.find(:first,:conditions=>{:title=>"fred"})
    
  end
  
  test "should add model type as pal" do
    login_as(:pal_user)
    assert_difference('ModelType.count',1) do
      post :create_model_metadata, :attribute=>"model_type",:model_type=>"fred"
    end
    
    assert_response :success
    assert_not_nil ModelType.find(:first,:conditions=>{:title=>"fred"})
    
  end
  
  test "should not add model type as non pal" do
    login_as(:aaron)
    assert_no_difference('ModelType.count') do
      post :create_model_metadata, :attribute=>"model_type",:model_type=>"fred"
    end
    
    assert_nil ModelType.find(:first,:conditions=>{:title=>"fred"})
    
  end
  
  test "should not add duplicate model type" do
    login_as(:quentin)
    m=model_types(:ODE)
    assert_no_difference('ModelType.count') do
      post :create_model_metadata, :attribute=>"model_type",:model_type=>m.title
    end
    
  end
  
  test "should add model format" do
    login_as(:quentin)
    assert_difference('ModelFormat.count',1) do
      post :create_model_metadata, :attribute=>"model_format",:model_format=>"fred"
    end
    
    assert_response :success
    assert_not_nil ModelFormat.find(:first,:conditions=>{:title=>"fred"})
    
  end
  
  test "should add model format as pal" do
    login_as(:pal_user)
    assert_difference('ModelFormat.count',1) do
      post :create_model_metadata, :attribute=>"model_format",:model_format=>"fred"
    end
    
    assert_response :success
    assert_not_nil ModelFormat.find(:first,:conditions=>{:title=>"fred"})
    
  end
  
  test "should not add model format as non pal" do
    login_as(:aaron)
    assert_no_difference('ModelFormat.count') do
      post :create_model_metadata, :attribute=>"model_format",:model_format=>"fred"
    end
    
    assert_nil ModelFormat.find(:first,:conditions=>{:title=>"fred"})
    
  end
  
  test "should not add duplicate model format" do
    login_as(:quentin)
    m=model_formats(:SBML)
    assert_no_difference('ModelFormat.count') do
      post :create_model_metadata, :attribute=>"model_format",:model_format=>m.title
    end
    
  end
  
  test "should update model format" do
    login_as(:quentin)
    m=model_formats(:SBML)
    
    assert_nil ModelFormat.find(:first,:conditions=>{:title=>"fred"})
    
    assert_no_difference('ModelFormat.count') do
      put :update_model_metadata, :attribute=>"model_format",:updated_model_format=>"fred",:updated_model_format_id=>m.id
    end
    
    assert_not_nil ModelFormat.find(:first,:conditions=>{:title=>"fred"})
  end
  
  test "should update model format as pal" do
    login_as(:pal_user)
    m=model_formats(:SBML)
    
    assert_nil ModelFormat.find(:first,:conditions=>{:title=>"fred"})
    
    assert_no_difference('ModelFormat.count') do
      put :update_model_metadata, :attribute=>"model_format",:updated_model_format=>"fred",:updated_model_format_id=>m.id
    end
    
    assert_not_nil ModelFormat.find(:first,:conditions=>{:title=>"fred"})
  end
  
  test "should not update model format as non pal" do
    login_as(:aaron)
    m=model_formats(:SBML)
    
    assert_nil ModelFormat.find(:first,:conditions=>{:title=>"fred"})
    
    assert_no_difference('ModelFormat.count') do
      put :update_model_metadata, :attribute=>"model_format",:updated_model_format=>"fred",:updated_model_format_id=>m.id
    end
    
    assert_nil ModelFormat.find(:first,:conditions=>{:title=>"fred"})
  end
  
  test "should update model type" do
    login_as(:quentin)
    m=model_types(:ODE)
    
    assert_nil ModelType.find(:first,:conditions=>{:title=>"fred"})
    
    assert_no_difference('ModelFormat.count') do
      put :update_model_metadata, :attribute=>"model_type",:updated_model_type=>"fred",:updated_model_type_id=>m.id
    end
    
    assert_not_nil ModelType.find(:first,:conditions=>{:title=>"fred"})
  end
  
  test "should update model type as pal" do
    login_as(:pal_user)
    m=model_types(:ODE)
    
    assert_nil ModelType.find(:first,:conditions=>{:title=>"fred"})
    
    assert_no_difference('ModelFormat.count') do
      put :update_model_metadata, :attribute=>"model_type",:updated_model_type=>"fred",:updated_model_type_id=>m.id
    end
    
    assert_not_nil ModelType.find(:first,:conditions=>{:title=>"fred"})
  end
  
  test "should not update model type as non pal" do
    login_as(:aaron)
    m=model_types(:ODE)
    
    assert_nil ModelType.find(:first,:conditions=>{:title=>"fred"})
    
    assert_no_difference('ModelFormat.count') do
      put :update_model_metadata, :attribute=>"model_type",:updated_model_type=>"fred",:updated_model_type_id=>m.id
    end
    
    assert_nil ModelType.find(:first,:conditions=>{:title=>"fred"})
  end
  
  def test_should_show_version
    m = models(:model_with_format_and_type)
    m.save! #to force creation of initial version (fixtures don't include it)
    old_desc=m.description
    old_desc_regexp=Regexp.new(old_desc)
    
    #create new version
    m.description="This is now version 2"
    assert m.save_as_new_version
    m = Model.find(m.id)
    assert_equal 2, m.versions.size
    assert_equal 2, m.version
    assert_equal 1, m.versions[0].version
    assert_equal 2, m.versions[1].version
    
    get :show, :id=>models(:model_with_format_and_type)
    assert_select "p", :text=>/This is now version 2/, :count=>1
    assert_select "p", :text=>old_desc_regexp, :count=>0
    
    get :show, :id=>models(:model_with_format_and_type), :version=>"2"
    assert_select "p", :text=>/This is now version 2/, :count=>1
    assert_select "p", :text=>old_desc_regexp, :count=>0
    
    get :show, :id=>models(:model_with_format_and_type), :version=>"1"
    assert_select "p", :text=>/This is now version 2/, :count=>0
    assert_select "p", :text=>old_desc_regexp, :count=>1
    
  end
  
  def test_should_create_new_version
    m=models(:model_with_format_and_type)    
    
    assert_difference("Model::Version.count", 1) do
      post :new_version, :id=>m, :model=>{:data=>fixture_file_upload('files/file_picture.png')}, :revision_comment=>"This is a new revision"
    end
    
    assert_redirected_to model_path(m)
    assert assigns(:model)
    assert_not_nil flash[:notice]
    assert_nil flash[:error]
    
    
    m=Model.find(m.id)
    assert_equal 2,m.versions.size
    assert_equal 2,m.version
    assert_equal "file_picture.png",m.original_filename
    assert_equal "file_picture.png",m.versions[1].original_filename
    assert_equal "Teusink.xml",m.versions[0].original_filename
    assert_equal "This is a new revision",m.versions[1].revision_comments
    
  end
  
  def valid_model
    { :title=>"Test",:data=>fixture_file_upload('files/little_file.txt')}
  end
  
  def valid_model_with_url
    { :title=>"Test",:data_url=>"http://www.sysmo-db.org/images/sysmo-db-logo-grad2.png"}
  end
  
  def valid_sharing
    {
      :use_whitelist=>"0",
      :user_blacklist=>"0",
      :sharing_scope=>Policy::ALL_REGISTERED_USERS,
      :permissions=>{:contributor_types=>ActiveSupport::JSON.encode("Person"),:values=>ActiveSupport::JSON.encode({})}
    }
  end
  
  def test_should_add_nofollow_to_links_in_show_page
    get :show, :id=> models(:model_with_links_in_description)    
    assert_select "div#description" do
      assert_select "a[rel=nofollow]"
    end
  end
  
  def test_update_should_not_overright_contributor
    login_as(:pal_user) #this user is a member of sysmo, and can edit this model
    model=models(:model_with_no_contributor)
    put :update, :id => model, :model => {:title=>"blah blah blah blah" }
    updated_model=assigns(:model)
    assert_redirected_to model_path(updated_model)
    assert_equal "blah blah blah blah",updated_model.title,"Title should have been updated"
    assert_nil updated_model.contributor,"contributor should still be nil"
  end
  
  test "filtering by assay" do
    assay=assays(:metabolomics_assay)
    get :index, :filter => {:assay => assay.id}
    assert_response :success
  end
  
  test "filtering by study" do
    study=studies(:metabolomics_study)
    get :index, :filter => {:study => study.id}
    assert_response :success
  end
  
  test "filtering by investigation" do
    inv=investigations(:metabolomics_investigation)
    get :index, :filter => {:investigation => inv.id}
    assert_response :success
  end
  
  test "filtering by project" do
    project=projects(:sysmo_project)
    get :index, :filter => {:project => project.id}
    assert_response :success
  end
  
  test "filtering by person" do
    person = people(:person_for_model_owner)
    get :index,:filter=>{:person=>person.id},:page=>"all"
    assert_response :success    
    m = models(:model_with_format_and_type)
    m2 = models(:model_with_different_owner)
    assert_select "div.list_items_container" do      
      assert_select "a",:text=>m.title,:count=>1
      assert_select "a",:text=>m2.title,:count=>0
    end
  end
  
end
