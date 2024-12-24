package Main.Schedule.act;

import java.util.ArrayList;

import Main.Schedule.GameData;
import Main.Schedule.object.Dynasty;
import Main.Schedule.object.Region;

public class city {
	public static GameData act(GameData gamedata, int num) {
		Region region = gamedata.getRegions().get(num);
		int act = (int) (Math.random()*3);
		switch (act) {
			case 0:
			case 1:
			default:
				System.out.print(region.getOccupy().getName()+" 행동..");
				break;
		}
		
		//관직 알고리즘
		if(region.getOffice()[0]==null && region.getSettled().size()>0) region.getOffice()[0] = region.getSettled().get((int) (Math.random()*region.getSettled().size()));
		
		//거주민 세금 거두기
		int tax_total = 0;
		for (int i = 0; i < region.getSettled().size(); i++) {
			Dynasty citizen = region.getSettled().get(i);
			int tax = (int) (citizen.getMoney()*0.1); //임시 가문세 10%
			citizen.setMoney(citizen.getMoney()-tax);
			region.setMoney(region.getMoney()+tax);
			tax_total+=tax;
		}
		System.out.print(" /총 "+tax_total+"의 세금을 거두었습니다.");
		
		//도시세 납부하기
		Region capital = region.getOccupy().getCapital();
		int tax2 = (int) (tax_total*0.1); //임시 도시세 10%
		capital.setMoney(capital.getMoney()+tax2);
		region.setMoney(region.getMoney()-tax2);
		System.out.print(" /도시세로 "+capital.getName()+"에"+tax2+"납부");
		
		//군인 봉급(10G, 일시불 - 100G)
		int salary_total = 0;
		for (int i = 0; i < region.getArmy().size(); i++) {
			Dynasty soldierDynasty = region.getArmy().get(i).getDynasty();
			region.setMoney(region.getMoney()-10);
			soldierDynasty.setMoney(soldierDynasty.getMoney()+10);
			salary_total+=10;
		}
		System.out.print(" /군인 유지비로 "+salary_total+"만큼 지출");
		
		//인접 지역 정복
		if((int) (Math.random()*4)==0) {
			for (int i = 0; i < region.getAdjacent().size(); i++) {
				//일단은 군사가 적은 인접지역 공격
				Region target = region.getAdjacent().get(i);
				if(region.getArmy().size() > target.getArmy().size() && region.getOccupy() != target.getOccupy()) {
					//일단은 1대1 대응 전투
					int survive = region.getArmy().size()-target.getArmy().size();
					for (int j = 0; j < survive; j++) {
						region.getArmy().remove((int) (Math.random()*region.getArmy().size()));	//랜덤 전사
					}
					target.setArmy(new ArrayList<>());
					if(target.getOccupy().getOccupies().size()<2 && target.getOccupy()!=gamedata.getFactions().get(0)) {
						gamedata.getFactions().remove(target.getOccupy());
						System.out.print(" /"+target.getOccupy().getName()+" 멸망..");
					}else {
						target.getOccupy().getOccupies().remove(target);
						//점령 도시가 수도라면 수도 이전
						if(target.getOccupy().getCapital()==target && target.getOccupy()!=gamedata.getFactions().get(0)) {
							Region newCapital = target.getOccupy().getOccupies().get((int) (Math.random()*target.getOccupy().getOccupies().size()));
							target.getOccupy().setCapital(newCapital);
							System.out.print(" /"+target.getOccupy().getName()+"의 새로운 수도 "+newCapital.getName());
						}
					}
					target.setOccupy(region.getOccupy());
					region.getOccupy().getOccupies().add(target);
					System.out.print(" /"+target.getName()+"이 "+region.getOccupy().getName()+"의 영토가 되었습니다!");
				}
			}
		}
	
		System.out.println();
		return gamedata;
	}
}
