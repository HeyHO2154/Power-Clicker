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
		System.out.print(dynasty.getName()+" 턴: ");
		int act = (int) (Math.random()*3);
		switch (act) {
			case 0:
				//인접한 지역 랜덤으로 선택
				Region moveLocation = dynasty.getLocation().getAdjacent().get((int) (Math.random()*(dynasty.getLocation().getAdjacent().size())));
				//해당 지역으로 이동
				dynasty.getLocation().getNomad().remove(dynasty);
				moveLocation.getNomad().add(dynasty);
				System.out.print(dynasty.getLocation().getName()+"에서 "+moveLocation.getName()+"로 이동");
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
					/*
					 * 이거 지형 생성할때, type(사막, 설원 등)이 매끄럽게 생성되게 시도해보자
					 * 사막 눈 사막 눈 이런식으로 뜬금뜬금 가면 몰입도 떨어지니까
					 */
					newLand = new Region(gamedata.getId(), (gamedata.getId()-1)+"지역", nature, 0);
					gamedata.getRegions().add(newLand);
					nature.getOccupy().add(newLand);
					System.out.println("asd");
				}
		        //인접지역으로 추가
		        newLand.getAdjacent().add(dynasty.getLocation());
		        dynasty.getLocation().getAdjacent().add(newLand);
		        //새로운 지역으로 이동
		        dynasty.getLocation().getNomad().remove(dynasty);
		        newLand.getNomad().add(dynasty);
				System.out.print("탐험 성공! "+dynasty.getLocation().getName()+"에서 "+newLand.getName()+"로 이동");
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
				System.out.print(" "+dynasty.getName()+"의 "+a.getName()+"와 "+B.getName()+"의 "+b.getName()+"가 결혼하였습니다. ");
				B.getMember().remove(b);
				if(B.getMember().size()==0) {
					System.out.print(" "+B.getName()+"이 흡수됨");
					dynasty.getLocation().getNomad().remove(B);
					gamedata.getDynasties().remove(B);
				}
				dynasty.getMember().add(b);
				a.setMarried(true);
				b.setMarried(true);
				int rand = (int) (Math.random()*4)+1;
				for (int i = 0; i < rand; i++) {
					Person baby = new Person(gamedata.getId(), "이름"+(gamedata.getId()-1), (int) (Math.random()*2), 0);
					dynasty.getMember().add(baby);
					System.out.print(" "+baby.getName()+"이 태어남");
				}
			}
		}
		
		System.out.println();
		return gamedata;
	}
}
