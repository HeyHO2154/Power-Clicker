package Main.Schedule.act;

import java.util.ArrayList;
import java.util.List;

import Main.Schedule.GameData;
import Main.Schedule.object.Dynasty;
import Main.Schedule.object.Faction;
import Main.Schedule.object.Person;
import Main.Schedule.object.Region;

public class nomad {
	public static GameData act(GameData gamedata, int num) {
		Dynasty dynasty = gamedata.getDynasties().get(num);
		int act = (int) (Math.random()*3);
		switch (act) {
			case 0:
				//인접한 지역 랜덤으로 선택
				Region moveLocation = dynasty.getLocation().getAdjacent().get((int) (Math.random()*(dynasty.getLocation().getAdjacent().size())));
				//해당 지역으로 이동
				dynasty.getLocation().getNomad().remove(dynasty);
				moveLocation.getNomad().add(dynasty);
				System.out.print(dynasty.getLocation().getName()+"에서 "+moveLocation.getName()+"로 이동");
				dynasty.setMoney(dynasty.getMoney()+(int) (Math.random()*5)); //수렵&채집
				dynasty.setLocation(moveLocation);
				break;
			case 1:
				if(dynasty.getLocation().getAdjacent().size() >= 4) {
					System.out.print("탐험 불가, "+dynasty.getLocation().getName()+"에 대기");
					break;
				}
				if((int) (Math.random()*gamedata.getRegions().size()) != 0) {
					if((int) (Math.random()*2)==0) {
						System.out.print("탐험 실패, "+dynasty.getName()+" 전멸\n");
						dynasty.getLocation().getNomad().remove(dynasty);
						gamedata.getDynasties().remove(dynasty);
						//전멸이므로 종료
						return gamedata;
					}else {
						System.out.print("탐험 실패, "+dynasty.getLocation().getName()+"에 대기");
					}
					break;
				}
				//새로운 지역으로 확장
				Faction nature = gamedata.getFactions().get(0);
				List<Region> nearLand = new ArrayList<>();
				//인접지역의 인접지역 중 랜덤하게 하나 선택
				for (int i = 0; i < dynasty.getLocation().getAdjacent().size(); i++) {
					for (int j = 0; j < dynasty.getLocation().getAdjacent().get(i).getAdjacent().size(); j++) {
						nearLand.add(dynasty.getLocation().getAdjacent().get(i).getAdjacent().get(j));
					}
				}
				Region newLand = nearLand.get((int) (Math.random()*nearLand.size()));
				//조건 안맞으면 아예 새 영토 생성
				if(newLand == dynasty.getLocation() || dynasty.getLocation().getAdjacent().contains(newLand) || newLand.getAdjacent().size()>=4) {
					int biome = dynasty.getLocation().getType();
					if((int) (Math.random()*4) == 0) {
						biome = (biome + (int) (Math.random()*3)+1)%4; //기존 바이옴이랑 안겹치게
					}
					newLand = new Region(gamedata.getId(), (gamedata.getId()-1)+"지역", nature, biome);
					gamedata.getRegions().add(newLand);
					nature.getOccupies().add(newLand);
				}
		        //인접지역으로 추가
		        newLand.getAdjacent().add(dynasty.getLocation());
		        dynasty.getLocation().getAdjacent().add(newLand);
		        //새로운 지역으로 이동
		        dynasty.getLocation().getNomad().remove(dynasty);
		        newLand.getNomad().add(dynasty);
				System.out.print("탐험 성공! "+dynasty.getLocation().getName()+"에서 "+newLand.getName()+"로 이동");
				dynasty.setMoney(dynasty.getMoney()+(int) (Math.random()*5)*10); //모험 보상 x10
				dynasty.setLocation(newLand);
				break;
			default:
				System.out.print(dynasty.getLocation().getName()+"에 대기");
				break;
		}
		
		//만나면 결혼
		Person a = dynasty.getMember().get((int) (Math.random()*dynasty.getMember().size()));
		if(!a.isMarried()) {
			//현 위치에서 랜덤 가문 선택, 거기서 랜덤 인원 선택
			Dynasty B = dynasty.getLocation().getNomad().get((int) (Math.random()*dynasty.getLocation().getNomad().size()));
			Person b = B.getMember().get((int) (Math.random()*B.getMember().size()));
			if(!b.isMarried() && a.getGender()!=b.getGender() && B!=dynasty) {
				//결혼 조건이 맞으면 진행
				System.out.print("/ "+dynasty.getName()+"의 "+a.getName()+"와 "+B.getName()+"의 "+b.getName()+"가 결혼하였습니다. ");
				B.getMember().remove(b);
				if(B.getMember().size()==0) {
					System.out.print("/ "+B.getName()+"이 흡수됨");
					dynasty.getLocation().getNomad().remove(B);
					gamedata.getDynasties().remove(B);
				}
				dynasty.getMember().add(b);
				a.setMarried(true);
				b.setMarried(true);
				int rand = (int) (Math.random()*4)+1;
				for (int i = 0; i < rand; i++) {
					Person baby = new Person(gamedata.getId(), "이름"+(gamedata.getId()-1), (int) (Math.random()*2), 0, dynasty);
					dynasty.getMember().add(baby);
					System.out.print("/ "+baby.getName()+"이 태어남");
				}
			}
		}
		
		//정착하기로 결심
		if((int) (Math.random()*10) == 1) {
			if(dynasty.getLocation().getOccupy()==gamedata.getFactions().get(0)) {
				if(dynasty.getMoney() >= 100) {
					//건국
					Faction newKingdom = new Faction(dynasty.getName()+"의 왕국", 1, dynasty.getLocation());
					dynasty.getLocation().getOccupy().getOccupies().remove(dynasty.getLocation());
					newKingdom.getOccupies().add(dynasty.getLocation());				
					dynasty.getLocation().setOccupy(newKingdom);
					dynasty.getLocation().getNomad().remove(dynasty);
					dynasty.getLocation().getSettled().add(dynasty);
					dynasty.setFaction(newKingdom);
					gamedata.getFactions().add(newKingdom);
					System.out.print("/ "+newKingdom.getName()+"이 "+dynasty.getLocation().getName()+"에 건국되었습니다.");
					newKingdom.setCapital(dynasty.getLocation());
					dynasty.getLocation().getOffice()[0] = dynasty;
					dynasty.setMoney(dynasty.getMoney()-100);
					dynasty.getLocation().setMoney(100);
				}else {
					System.out.print("/ 건국하려 했으나 자금이 모자랍니다..");
				}
			}else {
				//합류
				Faction Kingdom = dynasty.getLocation().getOccupy();
				dynasty.getLocation().getNomad().remove(dynasty);
				dynasty.getLocation().getSettled().add(dynasty);
				dynasty.setFaction(Kingdom);
				System.out.print("/ "+Kingdom.getName()+"에 "+dynasty.getName()+"가 합류하였습니다.");
			}
		}
		
		
		System.out.println();
		return gamedata;
	}
}
