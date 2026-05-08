import SwiftUI

struct VarnamView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            BackgroundView().ignoresSafeArea()

            VStack(spacing: 0) {

                // ── Top bar ───────────────────────────────────────────────
                HStack {
                    Button { dismiss() } label: {
                        HStack(spacing: 5) {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 11, weight: .light))
                            Text("Back")
                                .font(.cormorant(16, italic: true))
                        }
                        .foregroundColor(.gold)
                    }
                    Spacer()
                }
                .padding(.horizontal, 20)
                .padding(.top, 18)
                .padding(.bottom, 12)

                // ── Header ────────────────────────────────────────────────
                VStack(spacing: 6) {
                    Text("Varnam")
                        .font(.cinzel(36, weight: .black))
                        .foregroundStyle(LinearGradient.goldGradient)
                        .minimumScaleFactor(0.6)
                        .lineLimit(1)

                    HStack(spacing: 10) {
                        GoldRule()
                        OmSymbol(size: 11)
                        GoldRule()
                    }
                    .padding(.horizontal, 48)
                    .padding(.vertical, 4)

                    Text("The centrepiece of a recital")
                        .font(.cormorant(14, italic: true))
                        .tracking(2)
                        .foregroundColor(.ivoryDim)
                }
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)
                .padding(.bottom, 20)

                Color.gold.opacity(0.22).frame(height: 1).padding(.horizontal, 24)

                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 20) {
                        // Telugu lyric (bold + underline)
                        Text("Manavi chei konda radha chakani Swami na.")
                            .font(.cormorant(17)).fontWeight(.bold).underline()
                            .foregroundColor(.ivory)
                            .multilineTextAlignment(.leading)

                        // English translation (bold)
                        Text("Will you not listen to my loving prayer, my beautiful beloved Lord?")
                            .font(.cormorant(17)).fontWeight(.bold)
                            .foregroundColor(.ivory)
                            .multilineTextAlignment(.leading)

                        // Emotions (italic)
                        Text("Emotions portrayed:\n1. Affection and contentment with the Lord\n2. Anxiety and desperation that the Lord is not listening to her\n3. Awe from the Lord's divine beauty\n4. Utter devotion")
                            .font(.cormorant(16, italic: true))
                            .foregroundColor(.ivoryDim)
                            .multilineTextAlignment(.leading)

                        // ── Second passage ────────────────────────────────────
                        Spacer().frame(height: 4)

                        // Telugu lyric (bold + underline)
                        Text("Mamata miri yun na nura")
                            .font(.cormorant(17)).fontWeight(.bold).underline()
                            .foregroundColor(.ivory)
                            .multilineTextAlignment(.leading)

                        // English translation (bold)
                        Text("My love for you never ceases to increase as you can see.")
                            .font(.cormorant(17)).fontWeight(.bold)
                            .foregroundColor(.ivory)
                            .multilineTextAlignment(.leading)

                        // Emotions (italic)
                        Text("Emotions portrayed:\n1. Show the heartfelt nature of the love\n2. Show the concerned state when the love starts to get overwhelming\n3. Show the pain that comes with being so overwhelmed by love but not receiving any response back")
                            .font(.cormorant(16, italic: true))
                            .foregroundColor(.ivoryDim)
                            .multilineTextAlignment(.leading)

                        // ── Third passage ─────────────────────────────────────
                        Spacer().frame(height: 4)

                        // Telugu lyric (underlined)
                        Text("Vinara Sri Tanja-purini velayo ma Brigadhisha")
                            .font(.cormorant(17)).underline()
                            .foregroundColor(.ivory)
                            .multilineTextAlignment(.leading)

                        // English translation (plain)
                        Text("Please listen to me, my beautiful Lord Brigadeeswarar, who dwells in the sacred town of Tanjore")
                            .font(.cormorant(17))
                            .foregroundColor(.ivory)
                            .multilineTextAlignment(.leading)

                        // Emotions (italic)
                        Text("Emotions portrayed:\n1. Awe at the Lord's glory\n2. Pride and confidence and majesty when acting as the Lord")
                            .font(.cormorant(16, italic: true))
                            .foregroundColor(.ivoryDim)
                            .multilineTextAlignment(.leading)

                        // ── Fourth passage ────────────────────────────────────
                        Spacer().frame(height: 4)

                        // Telugu lyric (underlined)
                        Text("Nee nu ne ra nami nanura nika muka madi loru.")
                            .font(.cormorant(17)).underline()
                            .foregroundColor(.ivory)
                            .multilineTextAlignment(.leading)

                        // English translation (plain)
                        Text("Upon you alone, endlessly from many births, I kept all my thoughts to myself every single day, I promise you are in my heart, believe me.")
                            .font(.cormorant(17))
                            .foregroundColor(.ivory)
                            .multilineTextAlignment(.leading)

                        // Emotions (italic)
                        Text("Emotions portrayed:\n1. Vulnerability at how she is opening up to him about the struggles she faced.\n2. Sincerity that it's always been him and no one else")
                            .font(.cormorant(16, italic: true))
                            .foregroundColor(.ivoryDim)
                            .multilineTextAlignment(.leading)

                        // ── Fifth passage ─────────────────────────────────────
                        Spacer().frame(height: 4)

                        // Telugu lyric (underlined)
                        Text("Nee neratanamu nee doratanamu neeke tabuna netsalasaga (Swami)")
                            .font(.cormorant(17)).underline()
                            .foregroundColor(.ivory)
                            .multilineTextAlignment(.leading)

                        // English translation (plain)
                        Text("For your beauty and your regal elegance, you can be compared only to yourself, my Lord.")
                            .font(.cormorant(17))
                            .foregroundColor(.ivory)
                            .multilineTextAlignment(.leading)

                        // Emotions (italic)
                        Text("Emotions portrayed:\n1. Glory when acting as Shiva\n2. Fascination at the Lord's power and position\n3. Utter devotion to the Lord")
                            .font(.cormorant(16, italic: true))
                            .foregroundColor(.ivoryDim)
                            .multilineTextAlignment(.leading)

                        // ── Sixth passage ─────────────────────────────────────
                        Spacer().frame(height: 4)

                        // Telugu lyric (underlined)
                        Text("Aporuna madi bramasi virahamano sagaramulo mukunchi teno chunnati.")
                            .font(.cormorant(17)).underline()
                            .foregroundColor(.ivory)
                            .multilineTextAlignment(.leading)

                        // English translation (plain)
                        Text("My mind is wandering in madness as I sink deep into the ocean of desire and devotion, till my condition has turned pitiful.")
                            .font(.cormorant(17))
                            .foregroundColor(.ivory)
                            .multilineTextAlignment(.leading)

                        // Emotions (italic)
                        Text("Emotions portrayed:\n1. Floating along helplessly and lost, just like a leaf in water, not being able to do anything and just being pulled along by the flow of the water\n2. Being overwhelmed by the distressing nature of everything that is happening to her")
                            .font(.cormorant(16, italic: true))
                            .foregroundColor(.ivoryDim)
                            .multilineTextAlignment(.leading)

                        // ── Seventh passage ───────────────────────────────────
                        Spacer().frame(height: 4)

                        // Telugu lyric (underlined)
                        Text("Pan te mela ra nato")
                            .font(.cormorant(17)).underline()
                            .foregroundColor(.ivory)
                            .multilineTextAlignment(.leading)

                        // English translation (plain)
                        Text("In anger now you turn your face away from me. Tell me, why are you doing this to me?")
                            .font(.cormorant(17))
                            .foregroundColor(.ivory)
                            .multilineTextAlignment(.leading)

                        // Emotions (italic)
                        Text("Emotions portrayed:\n1. Hostility when acting as Shiva\n2. Confusion and desperation and pleading when acting as the main character - pleading for Shiva to tell her why he's suddenly so mad at her")
                            .font(.cormorant(16, italic: true))
                            .foregroundColor(.ivoryDim)
                            .multilineTextAlignment(.leading)

                        // ── Eighth passage ────────────────────────────────────
                        Spacer().frame(height: 4)

                        // Telugu lyric (underlined)
                        Text("Swami nee sati dora ne ka nara.")
                            .font(.cormorant(17)).underline()
                            .foregroundColor(.ivory)
                            .multilineTextAlignment(.leading)

                        // English translation (plain)
                        Text("My Lord, I've never seen anyone who could be compared to you.")
                            .font(.cormorant(17))
                            .foregroundColor(.ivory)
                            .multilineTextAlignment(.leading)

                        // Emotions (italic)
                        Text("Emotions portrayed:\n1. Utter devotion\n2. Glory when acting as Shiva\n3. Fascination in showing that in the vast world there isn't one person who could reach his level.")
                            .font(.cormorant(16, italic: true))
                            .foregroundColor(.ivoryDim)
                            .multilineTextAlignment(.leading)

                        // ── Ninth passage ─────────────────────────────────────
                        Spacer().frame(height: 4)

                        // Telugu lyric (underlined)
                        Text("Pancha sharudu vidu vanchi sharankunagu minchina velalo vanchana lediki.")
                            .font(.cormorant(17)).underline()
                            .foregroundColor(.ivory)
                            .multilineTextAlignment(.leading)

                        // English translation (plain)
                        Text("The five flowers of Cupid's bow have pierced my heart and my suffering has worsened. How can you be so indifferent to my pain?")
                            .font(.cormorant(17))
                            .foregroundColor(.ivory)
                            .multilineTextAlignment(.leading)

                        // Emotions (italic)
                        Text("Emotions:\n1. Fierce\n2. Pain from the cupid's bow\n3. Indifference when acting as Shiva\n4. Heartbreak and hurt from Lord Shiva's indifference.")
                            .font(.cormorant(16, italic: true))
                            .foregroundColor(.ivoryDim)
                            .multilineTextAlignment(.leading)

                        // ── Tenth passage ─────────────────────────────────────
                        Spacer().frame(height: 4)

                        // Telugu lyric (underlined)
                        Text("Dara di pati yeni dora doralu pokanera karinjanula tara tare meriki\nKalushi mella tira nabai tripa sudara marulu michi nara nanu che kora")
                            .font(.cormorant(17)).underline()
                            .foregroundColor(.ivory)
                            .multilineTextAlignment(.leading)

                        // English translation (plain)
                        Text("In the entire universe, you are the king of all kings. All the poets sing praises of you, you bestow fulfillment with forgiveness in your heart, as you remove all our difficulties. Please show some compassion to me and see how deep my love is for you. Please take me with you my Lord.")
                            .font(.cormorant(17))
                            .foregroundColor(.ivory)
                            .multilineTextAlignment(.leading)

                        // Emotions (italic)
                        Text("Emotions:\n1. Showing the vast nature of the world\n2. Glory when saying Shiva is the king of the kings\n3. Devotion when saying the poets sing praises of Shiva\n4. Compassion when saying that he bestows fulfilment\n5. Distress when talking about their difficulties and gratefulness when saying Shiva got rid of them\n6. Love and affection in her eyes as she offers herself to him.")
                            .font(.cormorant(16, italic: true))
                            .foregroundColor(.ivoryDim)
                            .multilineTextAlignment(.leading)
                    }
                    .padding(.horizontal, 28)
                    .padding(.vertical, 24)
                }

                Spacer(minLength: 0)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
}
