package Main.Game;

import java.util.ArrayList;
import java.util.Comparator;
import java.util.List;
import java.util.Map;

public class GameAct {
	
		//밤 행동 메서드
		static void Kill(int a, int b, Game gameData) {
			int[] pick = gameData.getPick();
			int kill = gameData.getKill();
			pick[a] = b;
			if(kill==-1) {
				kill = b;
			}else{
				int rand = (int) (Math.random()*2); //마피아 3인 이상은 다수결
				if(rand==0) {
					kill = b;
				}
			};
			gameData.setPick(pick);
			gameData.setKill(kill);
		}
		static void Live(int a, int b, Game gameData) {
			int[] pick = gameData.getPick();
			int live = gameData.getLive();
			pick[a] = b;
			live = b;
			gameData.setPick(pick);
			gameData.setLive(live);
		}
		static void Find(int a, int b, Game gameData) {
			int[] Job = gameData.getJob();
			int[] pick = gameData.getPick();
			boolean[] find = gameData.getFind();
			pick[a] = b;
			if(Job[b]==-1) {
				find[b] = true;
			}
			gameData.setJob(Job);
			gameData.setPick(pick);
			gameData.setFind(find);
		}
		
		//a->b 공론화
		static String Suspect(int a, int b, Game gameData) {
			int[] suspect_num = gameData.getSuspect_num();
			int[] Job_claim = gameData.getJob_claim();
			Map<Integer, List<Integer>> Enemy = gameData.getEnemy();
			Enemy.get(b).add(a);
			suspect_num[b]++;
			//경찰은 공론화+1
			if(Job_claim[a]==1) {
				Enemy.get(b).add(a);
				suspect_num[b]++;
			}
			gameData.setSuspect_num(suspect_num);
			gameData.setJob_claim(Job_claim);
			gameData.setEnemy(Enemy);
			return "저는 "+b+"를 의심합니다";
		}
		//직업공개 후 누굴 지목했는지 밝힘
		static String OpenJob(int i, Game gameData) {
			String message = null; //이게 그냥 지정해주면 초기화될지모르니, 초반에만 한번 초기화해주고 추가해주는 형식으로 가야겠는데
			int[] Job_claim = gameData.getJob_claim();
			int[] Job = gameData.getJob();
			boolean[] find = gameData.getFind();
			int[] pick = gameData.getPick();
			int[] pick_fake = gameData.getPick_fake();
			boolean[] find_fake = gameData.getFind_fake();
			Map<Integer, List<Integer>> Enemy = gameData.getEnemy();
			if(Job_claim[i]==99) {
				Job_claim[i]=Job[i];
			}
			switch(Job[i]){
				case -1:
					switch(Job_claim[i]){
					case 0:
						message = "저는 시민이에요";
						break;
					case 1:
						message = "저는 경찰이고, 조사결과 "+pick[i]+"는 "+find_fake[pick_fake[i]]+"입니다.";
						//조사결과 마피아라고 구라치면 공론화, 그 외 상대호의 획득
						if(find_fake[pick_fake[i]]) {
							message += "\n"+Suspect(i, pick_fake[i], gameData);
						}else {
							if(Enemy.get(pick_fake[pick_fake[i]]).contains(pick_fake[i])) {
								for (int j = 0; j < Enemy.get(pick_fake[pick_fake[i]]).size(); j++) {
									if(Enemy.get(pick_fake[pick_fake[i]]).get(j)==pick_fake[i]) {
										Enemy.get(pick_fake[pick_fake[i]]).remove(j);
									}
								}
							}
						}
						break;
					case 2:
						message = "저는 의사고, 살린 사람은 "+pick_fake[i]+"입니다.";
						break;
					}
					break;
				case 0:
					message = "저는 시민이에요";
					break;
				case 1:
					message = "저는 경찰이고, 조사결과 "+pick[i]+"는 "+find[pick[i]]+"입니다.";
					if(Job[pick[i]]==-1) {
						//조사결과 마피아일 때는 공론화
						message += "\n"+Suspect(i, pick[i], gameData);
					}else {
						//조사결과 시민일 때는 상호 적대리스트 삭제
						if(Enemy.get(i).contains(pick[i])) {
							for (int j = 0; j < Enemy.get(i).size(); j++) {
								if(Enemy.get(i).get(j)==pick[i]) {
									Enemy.get(i).remove(j);
								}
							}
						}
						if(Enemy.get(pick[i]).contains(i)) {
							for (int j = 0; j < Enemy.get(pick[i]).size(); j++) {
								if(Enemy.get(pick[i]).get(j)==i) {
									Enemy.get(pick[i]).remove(j);
								}
							}
						}
					}
					break;
				case 2:
					message = "저는 의사고, 살린 사람은 "+pick[i]+"입니다.";
					break;
			}
			//동일직업은 "의견내기" 추가 자동시행
			for (int j = 0; j < Job_claim.length; j++) {
				if(Job_claim[i]==Job_claim[j] && i!=j && Job_claim[i]!=0 && AliveAll(gameData).contains(j)) {
					if(Job_claim[i]==1) {
						message += "\n제가 진짜 경찰인데, "+j+"가 거짓말하네요?";
					}else if(Job_claim[i]==2){
						message += "\n제가 진짜 의사인데, "+j+"가 거짓말하네요?";
					}
					message += "\n"+Suspect(i, j, gameData);
				}
			}
			gameData.setJob_claim(Job_claim);
			gameData.setJob(Job);
			gameData.setEnemy(Enemy);
			gameData.setFind(find);
			gameData.setPick(pick);
			gameData.setPick_fake(pick_fake);
			gameData.setFind_fake(find_fake);
			return message;
		}
		//가짜 직업활동
		static void FakeJob(int i, Game gameData) {
			int[] Job_claim = gameData.getJob_claim();
			int[] pick_fake = gameData.getPick_fake();
			boolean[] find_fake = gameData.getFind_fake();
			Map<Integer, List<Integer>> Alive = gameData.getAlive();
			//가짜 직업 공개
			if(Job_claim[i]==99) {
				Job_claim[i] =  (int) (Math.random()*3);
			}
			if(Job_claim[i]==1) {
				if((int) (Math.random()*2) == 0) {
					pick_fake[i] = RandomWho(Alive.get(1), i);
					find_fake[pick_fake[i]] = true;
				}else {
					pick_fake[i] = RandomWho(Alive.get(-1), i);
					find_fake[pick_fake[i]] = false;
				}
			}else if(Job_claim[i]==2) {
				pick_fake[i] = RandomWho(AliveAll(gameData), i);
			}
			gameData.setJob_claim(Job_claim);
			gameData.setPick_fake(pick_fake);
			gameData.setFind_fake(find_fake);
			gameData.setAlive(Alive);
		}
		static String Nothing(int i, Game gameData) {
			int[] suspect_num = gameData.getSuspect_num();
			suspect_num[i]++;
			gameData.setSuspect_num(suspect_num);
			return "누구지..";
		}
		
		//게임에서 추방
		static void Kick(int i, Game gameData) {
			Map<Integer, List<Integer>> Alive = gameData.getAlive();
			Map<Integer, List<Integer>> Enemy = gameData.getEnemy();
			//생존자 명단에서 제거
			if(Alive.get(-1).contains(i)) {
				for (int j = 0; j < Alive.get(-1).size(); j++) {
					if(Alive.get(-1).get(j)==i) {
						Alive.get(-1).remove(j--);
					}
				}
			}else if(Alive.get(1).contains(i)) {
				for (int j = 0; j < Alive.get(1).size(); j++) {
					if(Alive.get(1).get(j)==i) {
						Alive.get(1).remove(j--);
					}
				}
			}
			//적대 목록에서 제거
			for (int j = 0; j < Enemy.size(); j++) {
				for (int k = 0; k < Enemy.get(j).size(); k++) {
					if(Enemy.get(j).get(k)==i) {
						Enemy.get(j).remove(k--);
					}
				}
			}
			Enemy.put(i, new ArrayList<>());
			gameData.setAlive(Alive);
			gameData.setEnemy(Enemy);
		}
		
		
		
		//본인 외 랜덤 인물
		static int RandomWho(List<Integer> list, int i) {
			int who;
			do {
				int rand = (int) (Math.random()*list.size());
				who = list.get(rand);
			} while (who==i);
			return who;
		}
		//현재 생존자 전체 목록
		static List<Integer> AliveAll(Game gameData){
			List<Integer> list = new ArrayList<>();
			list.addAll(gameData.getAlive().get(1));
			list.addAll(gameData.getAlive().get(-1));
			return list;
		}
		//가장 큰 번호 찾기
		static List<Integer> FindMaxNum(int[] list) {
			int max = 0;
			List<Integer> MaxNum = new ArrayList<>();
			for (int i = 0; i < list.length; i++) {
				if(list[i]>max) {
					max = list[i];
					MaxNum = new ArrayList<>();
				}
				if(list[i]==max) {
					MaxNum.add(i);
				}
			}
			MaxNum.sort(Comparator.reverseOrder());
			return MaxNum;
		}
		
}
